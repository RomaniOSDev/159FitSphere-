import AudioToolbox
import SwiftUI

struct Feature1View: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel = Feature1ViewModel()

    @State private var roundsText: String = "5"
    @State private var roundsShake: CGFloat = 0
    @State private var roundsError: String?
    @State private var startScale: CGFloat = 1.0
    @State private var showSuccessFlash = false
    @State private var showSavePresetSheet = false
    @State private var newPresetName: String = ""

    private var isSceneActive: Bool {
        scenePhase == .active
    }

    private var showTimerEmptyState: Bool {
        store.timerPrefsTouched == false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if showTimerEmptyState {
                        emptyState
                    }

                    if viewModel.isIdle {
                        timerPresetsSection
                        configurationSection
                        startSection
                    } else {
                        activeSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Interval Timer")
            .navigationBarTitleDisplayMode(.inline)
            .tint(Color.appPrimary)
            .onAppear {
                roundsText = String(store.roundsCount)
            }
            .onChange(of: store.roundsCount) { newValue in
                if viewModel.isIdle {
                    roundsText = String(newValue)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                viewModel.stop()
                roundsText = String(store.roundsCount)
            }
            .sheet(isPresented: $showSavePresetSheet) {
                savePresetSheet
            }
        }
    }

    private var savePresetSheet: some View {
        NavigationStack {
            ZStack {
                AppChromeBackground()
                Form {
                    Section {
                        TextField("Preset name", text: $newPresetName)
                            .foregroundStyle(Color.appTextPrimary)
                    } header: {
                        Text("Save current work, rest, and rounds")
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticSound.tapLight()
                        newPresetName = ""
                        showSavePresetSheet = false
                    }
                    .foregroundStyle(Color.appTextPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        HapticSound.impactMedium()
                        store.addCustomTimerPreset(
                            name: newPresetName,
                            work: store.workDurationSec,
                            rest: store.restDurationSec,
                            rounds: store.roundsCount
                        )
                        newPresetName = ""
                        showSavePresetSheet = false
                    }
                    .foregroundStyle(Color.appPrimary)
                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .tint(Color.appPrimary)
        }
    }

    private var timerPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick presets")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: 10) {
                presetButton(title: "Tabata") {
                    applyTimerPreset(work: 20, rest: 10, rounds: 8)
                }
                presetButton(title: "EMOM") {
                    applyTimerPreset(work: 60, rest: 0, rounds: 12)
                }
            }

            if store.customTimerPresets.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.customTimerPresets) { preset in
                            Button {
                                HapticSound.tapLight()
                                applyTimerPreset(
                                    work: preset.workDurationSec,
                                    rest: preset.restDurationSec,
                                    rounds: preset.roundsCount
                                )
                            } label: {
                                Text(preset.name)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .fitSphereCapsuleChip()
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    HapticSound.tapLight()
                                    store.removeCustomTimerPreset(id: preset.id)
                                }
                            }
                        }
                    }
                }
            }

            Button {
                HapticSound.tapLight()
                newPresetName = ""
                showSavePresetSheet = true
            } label: {
                Text("Save current as preset")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private func presetButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticSound.tapLight()
            action()
        }) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .fitSpherePrimaryButton(cornerRadius: 14)
        }
        .buttonStyle(.plain)
    }

    private func applyTimerPreset(work: Int, rest: Int, rounds: Int) {
        store.setWorkDuration(work)
        store.setRestDuration(rest)
        store.setRoundsCount(rounds)
        roundsText = String(rounds)
        store.markTimerPrefsTouched()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.appAccent)

            Text("Configure your first workout interval")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)

            Text("Use the sliders and rounds field, then start when you're ready.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .fitSpherePanel(cornerRadius: 18)
    }

    private var configurationSection: some View {
        VStack(spacing: 14) {
            sliderBlock(
                title: "Work Duration",
                valueLabel: "\(store.workDurationSec)s",
                value: Binding(
                    get: { Double(store.workDurationSec) },
                    set: { newValue in
                        HapticSound.tapLight()
                        store.markTimerPrefsTouched()
                        store.setWorkDuration(Int(newValue.rounded()))
                    }
                ),
                range: 5...180,
                step: 1
            )

            sliderBlock(
                title: "Rest Duration",
                valueLabel: "\(store.restDurationSec)s",
                value: Binding(
                    get: { Double(store.restDurationSec) },
                    set: { newValue in
                        HapticSound.tapLight()
                        store.markTimerPrefsTouched()
                        store.setRestDuration(Int(newValue.rounded()))
                    }
                ),
                range: 0...120,
                step: 1
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Rounds")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                TextField("Rounds", text: $roundsText)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .fitSphereInsetPanel(cornerRadius: 12)
                    .shake(trigger: roundsShake)
                    .onChange(of: roundsText) { newValue in
                        let filtered = newValue.filter(\.isNumber)
                        if filtered != newValue {
                            roundsText = filtered
                        }
                        commitRoundsIfPossible()
                    }

                if let roundsError {
                    Text(roundsError)
                        .font(.footnote)
                        .foregroundStyle(Color.appPrimary.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fitSpherePanel(cornerRadius: 16)
    }

    private func sliderBlock(
        title: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text(valueLabel)
                    .foregroundStyle(Color.appTextSecondary)
                    .monospacedDigit()
            }

            Slider(value: value, in: range, step: step)
                .tint(Color.appAccent)
        }
    }

    private var startSection: some View {
        Button {
            startWorkout()
        } label: {
            Text("Start Workout")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.appTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .fitSpherePrimaryButton(cornerRadius: 16)
        }
        .scaleEffect(startScale)
        .buttonStyle(.plain)
    }

    private func startWorkout() {
        roundsError = nil
        guard validateRoundsField() else {
            HapticSound.warningNotification()
            roundsShake += 1
            roundsError = "Enter a valid number of rounds (1–99)."
            return
        }

        HapticSound.impactMedium()
        AudioServicesPlaySystemSound(1104)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
            startScale = 0.97
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 140_000_000)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                startScale = 1.0
            }
        }

        viewModel.start(work: store.workDurationSec, rest: store.restDurationSec, rounds: store.roundsCount)
    }

    private var activeSection: some View {
        VStack(spacing: 16) {
            TimelineView(.periodic(from: .now, by: 0.2)) { context in
                ActiveIntervalTimelineContent(
                    now: context.date,
                    isSceneActive: isSceneActive,
                    viewModel: viewModel,
                    work: store.workDurationSec,
                    rest: store.restDurationSec,
                    rounds: store.roundsCount,
                    onSessionComplete: {
                        completeSessionFeedback()
                    },
                    formatSeconds: formatSeconds
                )
            }

            HStack(spacing: 12) {
                Button {
                    HapticSound.tapLight()
                    switch viewModel.runState {
                    case .running:
                        viewModel.pause()
                    case .paused:
                        HapticSound.impactMedium()
                        viewModel.resume()
                    default:
                        break
                    }
                } label: {
                    let title: String = {
                        if case .paused = viewModel.runState { return "Resume" }
                        return "Pause"
                    }()
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .fitSphereInsetPanel(cornerRadius: 16)
                }
                .buttonStyle(.plain)
                .disabled(isPhaseActionDisabled)

                Button {
                    HapticSound.tapLight()
                    viewModel.stop()
                } label: {
                    Text("Stop")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .fitSphereInsetPanel(cornerRadius: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.appPrimary.opacity(0.55), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            SuccessFlashView(isVisible: showSuccessFlash)
                .padding(.top, 6)
        }
    }

    private var isPhaseActionDisabled: Bool {
        if case .idle = viewModel.runState { return true }
        return false
    }

    private func completeSessionFeedback() {
        let work = store.workDurationSec
        let rest = store.restDurationSec
        let rounds = store.roundsCount
        let totalSec = (work * rounds) + (rest * max(0, rounds - 1))
        let minutes = max(1, Int(ceil(Double(totalSec) / 60.0)))

        store.recordWorkoutSessionCompleted(minutes: minutes, source: .intervalTimer, routineName: nil)

        HapticSound.successNotification()
        AudioServicesPlaySystemSound(1057)

        showSuccessFlash = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showSuccessFlash = false
        }
    }

    private func commitRoundsIfPossible() {
        guard let value = Int(roundsText), (1...99).contains(value) else { return }
        store.markTimerPrefsTouched()
        store.setRoundsCount(value)
        roundsError = nil
    }

    private func validateRoundsField() -> Bool {
        guard let value = Int(roundsText), (1...99).contains(value) else { return false }
        store.setRoundsCount(value)
        return true
    }

    private func formatSeconds(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct ActiveIntervalTimelineContent: View {
    let now: Date
    let isSceneActive: Bool
    @ObservedObject var viewModel: Feature1ViewModel
    let work: Int
    let rest: Int
    let rounds: Int
    let onSessionComplete: () -> Void
    let formatSeconds: (Int) -> String

    var body: some View {
        let _ = performTick()

        let label = viewModel.label(for: viewModel.runState)
        let seconds = viewModel.remainingSeconds(for: viewModel.runState, now: now) ?? 0
        let roundsInfo = viewModel.roundDisplay(for: viewModel.runState, rounds: rounds)

        VStack(spacing: 10) {
            Text(label)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            Text(formatSeconds(seconds))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appAccent)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("Round \(roundsInfo.current) / \(roundsInfo.total)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .fitSpherePanel(cornerRadius: 18)
    }

    private func performTick() {
        guard isSceneActive else { return }
        viewModel.tick(
            now: now,
            work: work,
            rest: rest,
            rounds: rounds,
            onCompletedSession: onSessionComplete
        )
    }
}
