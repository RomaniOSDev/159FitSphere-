import AudioToolbox
import SwiftUI

struct AddRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppDataStore

    @State private var name: String = ""
    @State private var category: RoutineCategory = .strength
    @State private var exerciseName: String = ""
    @State private var exerciseInstructions: String = ""
    @State private var exerciseMetric: String = ""
    @State private var exercises: [RoutineExercise] = []

    @State private var nameShake: CGFloat = 0
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppChromeBackground()

                Form {
                    Section {
                        TextField("Routine name", text: $name)
                            .foregroundStyle(Color.appTextPrimary)
                            .shake(trigger: nameShake)

                        Picker("Category", selection: $category) {
                            ForEach(RoutineCategory.allCases) { value in
                                Text(value.rawValue).tag(value)
                            }
                        }
                        .foregroundStyle(Color.appTextPrimary)
                    } header: {
                        RoutineFormHeader(title: "Details")
                    }

                    Section {
                        TextField("Exercise name", text: $exerciseName)
                            .foregroundStyle(Color.appTextPrimary)
                        TextField("Instructions", text: $exerciseInstructions, axis: .vertical)
                            .lineLimit(3...6)
                            .foregroundStyle(Color.appTextPrimary)
                        TextField("Sets / reps / duration (e.g., 3 × 12 or 5 min)", text: $exerciseMetric)
                            .foregroundStyle(Color.appTextPrimary)

                        Button {
                            addExerciseDraft()
                        } label: {
                            Text("Add Exercise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.appPrimary)
                        .controlSize(.large)
                    } header: {
                        RoutineFormHeader(title: "New exercise")
                    }

                    if exercises.isEmpty == false {
                        Section {
                            ForEach(exercises) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.name)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .font(.headline)
                                    Text(item.metric)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .font(.subheadline)

                                    if item.instructions.isEmpty == false {
                                        Text(item.instructions)
                                            .foregroundStyle(Color.appTextSecondary)
                                            .font(.footnote)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .onDelete { indexSet in
                                HapticSound.tapLight()
                                exercises.remove(atOffsets: indexSet)
                            }
                        } header: {
                            RoutineFormHeader(title: "Exercises")
                        }
                    }

                    if let validationMessage {
                        Section {
                            Text(validationMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticSound.tapLight()
                        dismiss()
                    }
                    .foregroundStyle(Color.appTextPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .foregroundStyle(Color.appPrimary)
                }
            }
            .tint(Color.appPrimary)
        }
    }

    private func addExerciseDraft() {
        validationMessage = nil
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMetric = exerciseMetric.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            HapticSound.warningNotification()
            validationMessage = "Exercise name can't be empty."
            return
        }

        guard trimmedMetric.isEmpty == false else {
            HapticSound.warningNotification()
            validationMessage = "Add a reps / duration label for this exercise."
            return
        }

        HapticSound.tapLight()
        let instructions = exerciseInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
        exercises.append(RoutineExercise(name: trimmedName, instructions: instructions, metric: trimmedMetric))
        exerciseName = ""
        exerciseInstructions = ""
        exerciseMetric = ""
    }

    private func saveRoutine() {
        validationMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false else {
            HapticSound.warningNotification()
            nameShake += 1
            validationMessage = "Routine name is required."
            return
        }

        guard exercises.isEmpty == false else {
            HapticSound.warningNotification()
            validationMessage = "Add at least one exercise."
            return
        }

        HapticSound.impactMedium()
        let routine = Routine(name: trimmedName, category: category, exercises: exercises)
        store.upsertRoutine(routine)
        store.registerMeaningfulActivity()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1057)

        dismiss()
    }
}

private struct RoutineFormHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .foregroundStyle(Color.appTextSecondary)
    }
}
