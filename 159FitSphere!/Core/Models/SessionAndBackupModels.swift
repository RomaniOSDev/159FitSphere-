import Foundation

enum WorkoutSessionSource: String, Codable, CaseIterable, Identifiable {
    case intervalTimer
    case routine

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .intervalTimer:
            return "Interval timer"
        case .routine:
            return "Routine"
        }
    }
}

struct SessionHistoryEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var completedAt: Date
    var durationMinutes: Int
    var source: WorkoutSessionSource
    var routineName: String?

    init(
        id: UUID = UUID(),
        completedAt: Date = Date(),
        durationMinutes: Int,
        source: WorkoutSessionSource,
        routineName: String? = nil
    ) {
        self.id = id
        self.completedAt = completedAt
        self.durationMinutes = durationMinutes
        self.source = source
        self.routineName = routineName
    }
}

struct SavedTimerPreset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var workDurationSec: Int
    var restDurationSec: Int
    var roundsCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        workDurationSec: Int,
        restDurationSec: Int,
        roundsCount: Int
    ) {
        self.id = id
        self.name = name
        self.workDurationSec = workDurationSec
        self.restDurationSec = restDurationSec
        self.roundsCount = roundsCount
    }
}

/// Full local backup for export/import (no server).
struct FitSphereBackup: Codable, Equatable {
    var formatVersion: Int
    var exportedAt: Date
    var hasSeenOnboarding: Bool
    var workDurationSec: Int
    var restDurationSec: Int
    var roundsCount: Int
    var timerPrefsTouched: Bool
    var routines: [Routine]
    var routinesSelectedCategoryRaw: String
    var sessionsCompleted: Int
    var totalWorkoutMinutes: Int
    var weeklyMinutes: [Int]
    var workoutsCompleted: Int
    var streakDays: Int
    var lastActivityDay: Date?
    var achievementsUnlocked: [String: Date]
    var totalAppUsageSeconds: Double
    var sessionHistory: [SessionHistoryEntry]
    var customTimerPresets: [SavedTimerPreset]
    var weeklyGoalMinutes: Int
}

enum WidgetSnapshotKeys {
    static let suiteName = "group.fitsphere159.shared"
    static let streak = "widget.streakDays"
    static let planLine = "widget.planLine"
    static let weekMinutes = "widget.weekMinutesSoFar"
}
