import SwiftUI

struct Feature2View: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = Feature2ViewModel()

    @State private var expandedRoutineIDs: Set<UUID> = []
    @State private var showAddRoutine = false
    @State private var pulseRoutineID: UUID?

    private var filteredRoutines: [Routine] {
        store.routines
            .filter { $0.category == store.routinesSelectedCategory }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 12) {
                    Picker("Category", selection: Binding(
                        get: { store.routinesSelectedCategory },
                        set: { newValue in
                            HapticSound.tapLight()
                            store.setRoutinesCategory(newValue)
                        }
                    )) {
                        ForEach(RoutineCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    List {
                        if filteredRoutines.isEmpty {
                            Section {
                                emptyState
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        } else {
                            ForEach(filteredRoutines) { routine in
                                Section {
                                    routineHeader(routine)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                HapticSound.tapLight()
                                                store.deleteRoutine(id: routine.id)
                                                expandedRoutineIDs.remove(routine.id)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }

                                            Button {
                                                HapticSound.tapLight()
                                                store.resetRoutineProgress(routineId: routine.id)
                                            } label: {
                                                Label("Reset", systemImage: "arrow.uturn.left")
                                            }
                                            .tint(Color.appAccent)
                                        }

                                    if expandedRoutineIDs.contains(routine.id) {
                                        routineDailyReminderRow(routineId: routine.id)
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)

                                        ForEach(routine.exercises) { exercise in
                                            exerciseDetail(routine: routine, exercise: exercise)
                                                .listRowBackground(Color.clear)
                                                .listRowSeparator(.hidden)
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button {
                                                        HapticSound.tapLight()
                                                        animatePulse(for: routine.id)
                                                        viewModel.toggleExerciseDone(
                                                            store: store,
                                                            routineId: routine.id,
                                                            exerciseId: exercise.id
                                                        )
                                                    } label: {
                                                        Text(exercise.isDone ? "Undo" : "Done")
                                                    }
                                                    .tint(Color.appPrimary)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Button {
                    HapticSound.tapLight()
                    showAddRoutine = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(width: 56, height: 56)
                        .background {
                            Circle()
                                .fill(FitSphereStyle.primaryButtonGradient)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 8)
                                .shadow(color: Color.appPrimary.opacity(0.45), radius: 20, x: 0, y: 4)
                        }
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 18)
                .padding(.bottom, 18)
                .accessibilityLabel("Add routine")
            }
            .navigationTitle("Routines")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineView()
                    .environmentObject(store)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                expandedRoutineIDs.removeAll()
                pulseRoutineID = nil
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.appAccent)

            Text("No routines yet. Tap + to create your first routine!")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .fitSpherePanel(cornerRadius: 18)
    }

    private func routineDailyReminderRow(routineId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's reminder")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)

            TextField(
                "Short note for today (optional)",
                text: routineDailyBinding(routineId: routineId),
                axis: .vertical
            )
            .lineLimit(1...4)
            .textFieldStyle(.plain)
            .foregroundStyle(Color.appTextPrimary)
            .padding(12)
            .fitSphereInsetPanel(cornerRadius: 12)
        }
        .padding(.vertical, 4)
    }

    private func routineDailyBinding(routineId: UUID) -> Binding<String> {
        Binding(
            get: { store.routines.first { $0.id == routineId }?.dailyReminderNote ?? "" },
            set: { store.setRoutineDailyNote(routineId: routineId, note: $0) }
        )
    }

    private func exerciseNoteBinding(routineId: UUID, exerciseId: UUID) -> Binding<String> {
        Binding(
            get: {
                guard let r = store.routines.first(where: { $0.id == routineId }),
                      let e = r.exercises.first(where: { $0.id == exerciseId }) else { return "" }
                return e.personalNote
            },
            set: { store.setExercisePersonalNote(routineId: routineId, exerciseId: exerciseId, note: $0) }
        )
    }

    private func routineHeader(_ routine: Routine) -> some View {
        let isExpanded = expandedRoutineIDs.contains(routine.id)

        return Button {
            HapticSound.tapLight()
            toggleExpanded(routine.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                routineCompletionRing(fraction: routine.completionFraction)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text("\(routine.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.25), value: isExpanded)
            }
            .padding(14)
            .fitSpherePanel(cornerRadius: 16, elevated: pulseRoutineID == routine.id)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        Color.appAccent.opacity(pulseRoutineID == routine.id ? 0.85 : 0),
                        lineWidth: pulseRoutineID == routine.id ? 2 : 0
                    )
                    .animation(.easeInOut(duration: 0.35), value: pulseRoutineID)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Reset progress") {
                HapticSound.tapLight()
                store.resetRoutineProgress(routineId: routine.id)
            }
        }
    }

    private func routineCompletionRing(fraction: Double) -> some View {
        let clamped = min(max(fraction.isFinite ? fraction : 0, 0), 1)
        return ZStack {
            Circle()
                .stroke(Color.appAccent.opacity(0.22), lineWidth: 4)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Color.appAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if clamped >= 0.999 {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.appAccent)
            }
        }
        .accessibilityLabel("Routine progress")
        .accessibilityValue("\(Int((clamped * 100).rounded())) percent")
    }

    private func exerciseDetail(routine: Routine, exercise: RoutineExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                    Text(exercise.metric)
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer(minLength: 0)

                if exercise.isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.appAccent)
                        .accessibilityLabel("Completed")
                }
            }

            if exercise.instructions.isEmpty == false {
                Text(exercise.instructions)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
            }

            TextField(
                "Exercise note (optional)",
                text: exerciseNoteBinding(routineId: routine.id, exerciseId: exercise.id),
                axis: .vertical
            )
            .lineLimit(1...3)
            .textFieldStyle(.plain)
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary)

            HStack {
                Text(exercise.isDone ? "Completed" : "Not completed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)

                Spacer()

                Button {
                    HapticSound.tapLight()
                    animatePulse(for: routine.id)
                    viewModel.toggleExerciseDone(store: store, routineId: routine.id, exerciseId: exercise.id)
                } label: {
                    Text(exercise.isDone ? "Undo" : "Mark done")
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.appTextPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .modifier(MarkDoneButtonChrome(isDone: exercise.isDone))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .fitSpherePanel(cornerRadius: 14, elevated: false)
        .padding(.leading, 6)
    }

    private func toggleExpanded(_ id: UUID) {
        if expandedRoutineIDs.contains(id) {
            expandedRoutineIDs.remove(id)
        } else {
            expandedRoutineIDs.insert(id)
        }
    }

    private func animatePulse(for routineID: UUID) {
        pulseRoutineID = routineID
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                if pulseRoutineID == routineID {
                    pulseRoutineID = nil
                }
            }
        }
    }
}

private struct MarkDoneButtonChrome: ViewModifier {
    let isDone: Bool

    func body(content: Content) -> some View {
        Group {
            if isDone {
                content
                    .fitSphereInsetPanel(cornerRadius: 12)
            } else {
                content
                    .fitSpherePrimaryButton(cornerRadius: 12)
            }
        }
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
