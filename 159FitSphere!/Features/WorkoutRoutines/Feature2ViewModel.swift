import AudioToolbox
import Combine
import Foundation

@MainActor
final class Feature2ViewModel: ObservableObject {

    func estimatedMinutes(for routine: Routine) -> Int {
        let sum = routine.exercises.reduce(0) { partial, exercise in
            partial + minutesFromMetric(exercise.metric)
        }
        return max(1, sum)
    }

    private func minutesFromMetric(_ metric: String) -> Int {
        let trimmed = metric.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        let numericPieces = trimmed
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Int.init)

        guard let firstNumber = numericPieces.first else {
            return 5
        }

        if lower.contains("min") {
            return max(1, firstNumber)
        }

        return 5
    }

    func toggleExerciseDone(store: AppDataStore, routineId: UUID, exerciseId: UUID) {
        guard let routineBefore = store.routines.first(where: { $0.id == routineId }) else { return }
        let wasFullyComplete = routineBefore.isFullyCompleted
        guard let exercise = routineBefore.exercises.first(where: { $0.id == exerciseId }) else { return }

        let newValue = exercise.isDone == false
        store.updateExercise(routineId: routineId, exerciseId: exerciseId, isDone: newValue)

        guard let routineAfter = store.routines.first(where: { $0.id == routineId }) else { return }
        if routineAfter.isFullyCompleted && wasFullyComplete == false {
            HapticSound.impactMedium()
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

            let minutes = estimatedMinutes(for: routineAfter)
            store.recordWorkoutSessionCompleted(minutes: minutes, source: .routine, routineName: routineAfter.name)
        }
    }
}
