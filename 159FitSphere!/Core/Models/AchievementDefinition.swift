import Foundation

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String

    func isUnlocked(store: AppDataStore) -> Bool {
        switch id {
        case "first_workout":
            return store.workoutsCompleted >= 1
        case "ten_sessions":
            return store.workoutsCompleted >= 10
        case "fifty_minutes":
            return store.totalWorkoutMinutes >= 50
        case "century_minutes":
            return store.totalWorkoutMinutes >= 100
        case "power_user":
            return store.workoutsCompleted >= 50
        case "streak_3":
            return store.streakDays >= 3
        case "streak_7":
            return store.streakDays >= 7
        case "time_invested":
            return store.totalAppUsageSeconds >= 3600
        default:
            return false
        }
    }
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_workout",
            title: "First Workout",
            description: "Completed your first workout session."
        ),
        AchievementDefinition(
            id: "ten_sessions",
            title: "10 Sessions",
            description: "Reached ten completed workout sessions."
        ),
        AchievementDefinition(
            id: "fifty_minutes",
            title: "50 Minute Mark",
            description: "Accumulated fifty total minutes of workout time."
        ),
        AchievementDefinition(
            id: "century_minutes",
            title: "Century Mark",
            description: "Amassed one hundred total workout minutes."
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            description: "Reached 50 items."
        ),
        AchievementDefinition(
            id: "streak_3",
            title: "Three-Day Streak",
            description: "Used the app 3 days in a row."
        ),
        AchievementDefinition(
            id: "streak_7",
            title: "Week-Long Habit",
            description: "Used the app 7 days in a row."
        ),
        AchievementDefinition(
            id: "time_invested",
            title: "Time Invested",
            description: "Spent 60 minutes total in the app."
        )
    ]
}
