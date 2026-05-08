import Foundation
import Combine

@MainActor
final class AppDataStore: ObservableObject {

    private enum Keys {
        static let hasSeenOnboarding = "fitsphere.hasSeenOnboarding"
        static let workDurationSec = "fitsphere.workDurationSec"
        static let restDurationSec = "fitsphere.restDurationSec"
        static let roundsCount = "fitsphere.roundsCount"
        static let timerPrefsTouched = "fitsphere.timerPrefsTouched"
        static let routinesJSON = "fitsphere.routinesJSON"
        static let routinesCategory = "fitsphere.routinesCategory"
        static let sessionsCompleted = "fitsphere.sessionsCompleted"
        static let totalWorkoutMinutes = "fitsphere.totalWorkoutMinutes"
        static let weeklyMinutesJSON = "fitsphere.weeklyMinutesJSON"
        static let workoutsCompleted = "fitsphere.workoutsCompleted"
        static let streakDays = "fitsphere.streakDays"
        static let lastActivityDay = "fitsphere.lastActivityDay"
        static let achievementsJSON = "fitsphere.achievementsJSON"
        static let totalAppUsageSeconds = "fitsphere.totalAppUsageSeconds"
        static let usageSessionStartedAt = "fitsphere.usageSessionStartedAt"
        static let sessionHistoryJSON = "fitsphere.sessionHistoryJSON"
        static let customTimerPresetsJSON = "fitsphere.customTimerPresetsJSON"
        static let weeklyGoalMinutes = "fitsphere.weeklyGoalMinutes"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published var workDurationSec: Int
    @Published var restDurationSec: Int
    @Published var roundsCount: Int
    @Published var timerPrefsTouched: Bool

    @Published private(set) var routines: [Routine]
    @Published var routinesSelectedCategory: RoutineCategory
    @Published private(set) var sessionsCompleted: Int
    @Published private(set) var totalWorkoutMinutes: Int
    @Published private(set) var weeklyMinutes: [Int]

    @Published private(set) var workoutsCompleted: Int
    @Published private(set) var streakDays: Int
    @Published private(set) var lastActivityDay: Date?
    @Published private(set) var achievementsUnlocked: [String: Date]

    @Published private(set) var totalAppUsageSeconds: Double

    @Published private(set) var sessionHistory: [SessionHistoryEntry]
    @Published private(set) var customTimerPresets: [SavedTimerPreset]
    @Published var weeklyGoalMinutes: Int

    @Published var softHintMessage: String?

    private var usageSessionStartedAt: Date?
    private var softHintDismissTask: Task<Void, Never>?

    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = userDefaults
        var cal = calendar
        cal.firstWeekday = 2
        self.calendar = cal

        self.hasSeenOnboarding = userDefaults.bool(forKey: Keys.hasSeenOnboarding)

        let work = userDefaults.object(forKey: Keys.workDurationSec) as? Int ?? 30
        let rest = userDefaults.object(forKey: Keys.restDurationSec) as? Int ?? 15
        let rounds = userDefaults.object(forKey: Keys.roundsCount) as? Int ?? 5

        self.workDurationSec = max(1, min(600, work))
        self.restDurationSec = max(0, min(600, rest))
        self.roundsCount = max(1, min(99, rounds))
        self.timerPrefsTouched = userDefaults.bool(forKey: Keys.timerPrefsTouched)

        if let data = userDefaults.data(forKey: Keys.routinesJSON),
           let decoded = try? decoder.decode([Routine].self, from: data) {
            self.routines = decoded
        } else {
            self.routines = []
        }

        if let raw = userDefaults.string(forKey: Keys.routinesCategory),
           let decoded = RoutineCategory(rawValue: raw) {
            self.routinesSelectedCategory = decoded
        } else {
            self.routinesSelectedCategory = .strength
        }

        self.sessionsCompleted = userDefaults.integer(forKey: Keys.sessionsCompleted)
        self.totalWorkoutMinutes = userDefaults.integer(forKey: Keys.totalWorkoutMinutes)
        self.workoutsCompleted = userDefaults.integer(forKey: Keys.workoutsCompleted)
        self.streakDays = userDefaults.integer(forKey: Keys.streakDays)

        if let weeklyData = userDefaults.data(forKey: Keys.weeklyMinutesJSON),
           let decoded = try? decoder.decode([Int].self, from: weeklyData),
           decoded.count == 7 {
            self.weeklyMinutes = decoded
        } else {
            self.weeklyMinutes = Array(repeating: 0, count: 7)
        }

        if let ts = userDefaults.object(forKey: Keys.lastActivityDay) as? TimeInterval {
            self.lastActivityDay = Date(timeIntervalSince1970: ts)
        } else {
            self.lastActivityDay = nil
        }

        if let achData = userDefaults.data(forKey: Keys.achievementsJSON) {
            if let decoded = try? decoder.decode([String: Date].self, from: achData) {
                self.achievementsUnlocked = decoded
            } else if let legacy = try? JSONDecoder().decode([String: Double].self, from: achData) {
                var mapped: [String: Date] = [:]
                for (k, v) in legacy {
                    mapped[k] = Date(timeIntervalSince1970: v)
                }
                self.achievementsUnlocked = mapped
            } else {
                self.achievementsUnlocked = [:]
            }
        } else {
            self.achievementsUnlocked = [:]
        }

        let usage = userDefaults.double(forKey: Keys.totalAppUsageSeconds)
        self.totalAppUsageSeconds = usage

        if let ts = userDefaults.object(forKey: Keys.usageSessionStartedAt) as? TimeInterval {
            self.usageSessionStartedAt = Date(timeIntervalSince1970: ts)
        } else {
            self.usageSessionStartedAt = nil
        }

        if let hData = userDefaults.data(forKey: Keys.sessionHistoryJSON),
           let decoded = try? decoder.decode([SessionHistoryEntry].self, from: hData) {
            self.sessionHistory = decoded
        } else {
            self.sessionHistory = []
        }

        if let pData = userDefaults.data(forKey: Keys.customTimerPresetsJSON),
           let decoded = try? decoder.decode([SavedTimerPreset].self, from: pData) {
            self.customTimerPresets = decoded
        } else {
            self.customTimerPresets = []
        }

        let goal = userDefaults.object(forKey: Keys.weeklyGoalMinutes) as? Int ?? 150
        self.weeklyGoalMinutes = max(0, min(600, goal))

        refreshAchievementMetadataIfNeeded()
        pushWidgetSnapshot()
    }

    func exportBackup() throws -> Data {
        let backup = FitSphereBackup(
            formatVersion: 1,
            exportedAt: Date(),
            hasSeenOnboarding: hasSeenOnboarding,
            workDurationSec: workDurationSec,
            restDurationSec: restDurationSec,
            roundsCount: roundsCount,
            timerPrefsTouched: timerPrefsTouched,
            routines: routines,
            routinesSelectedCategoryRaw: routinesSelectedCategory.rawValue,
            sessionsCompleted: sessionsCompleted,
            totalWorkoutMinutes: totalWorkoutMinutes,
            weeklyMinutes: weeklyMinutes,
            workoutsCompleted: workoutsCompleted,
            streakDays: streakDays,
            lastActivityDay: lastActivityDay,
            achievementsUnlocked: achievementsUnlocked,
            totalAppUsageSeconds: totalAppUsageSeconds,
            sessionHistory: sessionHistory,
            customTimerPresets: customTimerPresets,
            weeklyGoalMinutes: weeklyGoalMinutes
        )
        return try encoder.encode(backup)
    }

    func importBackup(data: Data) throws {
        let backup = try decoder.decode(FitSphereBackup.self, from: data)
        guard backup.formatVersion == 1 else {
            throw NSError(domain: "FitSphereBackup", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported backup version."])
        }

        hasSeenOnboarding = backup.hasSeenOnboarding
        defaults.set(backup.hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)

        workDurationSec = max(1, min(600, backup.workDurationSec))
        restDurationSec = max(0, min(600, backup.restDurationSec))
        roundsCount = max(1, min(99, backup.roundsCount))
        timerPrefsTouched = backup.timerPrefsTouched
        defaults.set(workDurationSec, forKey: Keys.workDurationSec)
        defaults.set(restDurationSec, forKey: Keys.restDurationSec)
        defaults.set(roundsCount, forKey: Keys.roundsCount)
        defaults.set(timerPrefsTouched, forKey: Keys.timerPrefsTouched)

        routines = backup.routines
        if let data = try? encoder.encode(backup.routines) {
            defaults.set(data, forKey: Keys.routinesJSON)
        }

        if let cat = RoutineCategory(rawValue: backup.routinesSelectedCategoryRaw) {
            routinesSelectedCategory = cat
        } else {
            routinesSelectedCategory = .strength
        }
        defaults.set(routinesSelectedCategory.rawValue, forKey: Keys.routinesCategory)

        sessionsCompleted = backup.sessionsCompleted
        totalWorkoutMinutes = backup.totalWorkoutMinutes
        workoutsCompleted = backup.workoutsCompleted
        streakDays = backup.streakDays
        defaults.set(sessionsCompleted, forKey: Keys.sessionsCompleted)
        defaults.set(totalWorkoutMinutes, forKey: Keys.totalWorkoutMinutes)
        defaults.set(workoutsCompleted, forKey: Keys.workoutsCompleted)
        defaults.set(streakDays, forKey: Keys.streakDays)

        var w = backup.weeklyMinutes
        if w.count != 7 { w = Array(repeating: 0, count: 7) }
        weeklyMinutes = w
        if let wData = try? encoder.encode(w) {
            defaults.set(wData, forKey: Keys.weeklyMinutesJSON)
        }

        lastActivityDay = backup.lastActivityDay
        if let day = lastActivityDay {
            defaults.set(day.timeIntervalSince1970, forKey: Keys.lastActivityDay)
        } else {
            defaults.removeObject(forKey: Keys.lastActivityDay)
        }

        achievementsUnlocked = backup.achievementsUnlocked
        saveAchievements()

        totalAppUsageSeconds = max(0, backup.totalAppUsageSeconds)
        defaults.set(totalAppUsageSeconds, forKey: Keys.totalAppUsageSeconds)

        sessionHistory = Array(backup.sessionHistory.prefix(500))
        saveSessionHistory()

        customTimerPresets = backup.customTimerPresets
        saveCustomPresets()

        weeklyGoalMinutes = max(0, min(600, backup.weeklyGoalMinutes))
        defaults.set(weeklyGoalMinutes, forKey: Keys.weeklyGoalMinutes)

        refreshAchievementMetadataIfNeeded()
        pushWidgetSnapshot()
    }

    func setWeeklyGoalMinutes(_ value: Int) {
        weeklyGoalMinutes = max(0, min(600, value))
        defaults.set(weeklyGoalMinutes, forKey: Keys.weeklyGoalMinutes)
        pushWidgetSnapshot()
    }

    func weeklyGoalProgressFraction() -> Double {
        guard weeklyGoalMinutes > 0 else { return 0 }
        let logged = minutesLoggedThisCalendarWeek()
        return min(1, Double(logged) / Double(weeklyGoalMinutes))
    }

    func minutesLoggedThisCalendarWeek() -> Int {
        guard let start = weekStart(for: Date()),
              let end = calendar.date(byAdding: .day, value: 7, to: start) else { return 0 }
        return sessionHistory
            .filter { $0.completedAt >= start && $0.completedAt < end }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func lastFourWeeksChartData() -> [(label: String, minutes: Int)] {
        guard let currentWeekStart = weekStart(for: Date()) else { return [] }
        var rows: [(String, Int)] = []
        for back in stride(from: 3, through: 0, by: -1) {
            guard let wkStart = calendar.date(byAdding: .weekOfYear, value: -back, to: currentWeekStart),
                  let wkEnd = calendar.date(byAdding: .day, value: 7, to: wkStart) else { continue }
            let sum = sessionHistory
                .filter { $0.completedAt >= wkStart && $0.completedAt < wkEnd }
                .reduce(0) { $0 + $1.durationMinutes }
            let m = calendar.component(.month, from: wkStart)
            let d = calendar.component(.day, from: wkStart)
            rows.append(("\(m)/\(d)", sum))
        }
        return rows
    }

    func pushWidgetSnapshot() {
        guard let shared = UserDefaults(suiteName: WidgetSnapshotKeys.suiteName) else { return }
        shared.set(streakDays, forKey: WidgetSnapshotKeys.streak)
        shared.set(computePlanSummaryLine(), forKey: WidgetSnapshotKeys.planLine)
        shared.set(minutesLoggedThisCalendarWeek(), forKey: WidgetSnapshotKeys.weekMinutes)
    }

    func computePlanSummaryLine() -> String {
        if let routine = routines.first(where: { $0.isFullyCompleted == false }) {
            let note = routine.dailyReminderNote.trimmingCharacters(in: .whitespacesAndNewlines)
            if note.isEmpty {
                return routine.name
            }
            return "\(routine.name) · \(note)"
        }
        return "\(roundsCount)×\(workDurationSec)s plan"
    }

    func addCustomTimerPreset(name: String, work: Int, rest: Int, rounds: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }
        let preset = SavedTimerPreset(
            name: trimmed,
            workDurationSec: max(1, min(600, work)),
            restDurationSec: max(0, min(600, rest)),
            roundsCount: max(1, min(99, rounds))
        )
        var next = customTimerPresets
        next.insert(preset, at: 0)
        customTimerPresets = next
        saveCustomPresets()
    }

    func removeCustomTimerPreset(id: UUID) {
        customTimerPresets = customTimerPresets.filter { $0.id != id }
        saveCustomPresets()
    }

    func setRoutineDailyNote(routineId: UUID, note: String) {
        guard let idx = routines.firstIndex(where: { $0.id == routineId }) else { return }
        var routine = routines[idx]
        routine.dailyReminderNote = note
        upsertRoutine(routine)
        pushWidgetSnapshot()
    }

    func setExercisePersonalNote(routineId: UUID, exerciseId: UUID, note: String) {
        guard let rIdx = routines.firstIndex(where: { $0.id == routineId }) else { return }
        var routine = routines[rIdx]
        guard let eIdx = routine.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        routine.exercises[eIdx].personalNote = note
        upsertRoutine(routine)
    }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func setWorkDuration(_ value: Int) {
        workDurationSec = max(1, min(600, value))
        defaults.set(workDurationSec, forKey: Keys.workDurationSec)
        pushWidgetSnapshot()
    }

    func setRestDuration(_ value: Int) {
        restDurationSec = max(0, min(600, value))
        defaults.set(restDurationSec, forKey: Keys.restDurationSec)
    }

    func setRoundsCount(_ value: Int) {
        roundsCount = max(1, min(99, value))
        defaults.set(roundsCount, forKey: Keys.roundsCount)
        pushWidgetSnapshot()
    }

    func markTimerPrefsTouched() {
        guard timerPrefsTouched == false else { return }
        timerPrefsTouched = true
        defaults.set(true, forKey: Keys.timerPrefsTouched)
    }

    func setRoutinesCategory(_ category: RoutineCategory) {
        routinesSelectedCategory = category
        defaults.set(category.rawValue, forKey: Keys.routinesCategory)
    }

    func replaceRoutines(_ items: [Routine]) {
        routines = items
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: Keys.routinesJSON)
        }
        pushWidgetSnapshot()
    }

    func upsertRoutine(_ routine: Routine) {
        var next = routines
        if let idx = next.firstIndex(where: { $0.id == routine.id }) {
            next[idx] = routine
        } else {
            next.insert(routine, at: 0)
        }
        replaceRoutines(next)
    }

    func deleteRoutine(id: UUID) {
        replaceRoutines(routines.filter { $0.id != id })
    }

    func updateExercise(routineId: UUID, exerciseId: UUID, isDone: Bool) {
        guard let rIdx = routines.firstIndex(where: { $0.id == routineId }) else { return }
        var routine = routines[rIdx]
        guard let eIdx = routine.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        routine.exercises[eIdx].isDone = isDone
        upsertRoutine(routine)
    }

    func resetRoutineProgress(routineId: UUID) {
        guard let rIdx = routines.firstIndex(where: { $0.id == routineId }) else { return }
        var routine = routines[rIdx]
        for i in routine.exercises.indices {
            routine.exercises[i].isDone = false
        }
        upsertRoutine(routine)
    }

    func recordWorkoutSessionCompleted(
        minutes: Int,
        source: WorkoutSessionSource,
        routineName: String? = nil
    ) {
        let safeMinutes = max(0, minutes)

        sessionsCompleted += 1
        workoutsCompleted += 1
        totalWorkoutMinutes += safeMinutes

        defaults.set(sessionsCompleted, forKey: Keys.sessionsCompleted)
        defaults.set(workoutsCompleted, forKey: Keys.workoutsCompleted)
        defaults.set(totalWorkoutMinutes, forKey: Keys.totalWorkoutMinutes)

        bumpWeeklyMinutesToday(by: safeMinutes)

        var history = sessionHistory
        history.insert(
            SessionHistoryEntry(
                completedAt: Date(),
                durationMinutes: safeMinutes,
                source: source,
                routineName: routineName
            ),
            at: 0
        )
        if history.count > 500 {
            history = Array(history.prefix(500))
        }
        sessionHistory = history
        saveSessionHistory()

        registerMeaningfulActivity()
        refreshAchievementMetadataIfNeeded()

        enqueueSoftHint()
        pushWidgetSnapshot()
    }

    private func enqueueSoftHint() {
        let message: String
        if streakDays >= 7 {
            message = "One week of consistency — great rhythm."
        } else if streakDays >= 3 {
            message = "Three days in a row — keep the momentum."
        } else {
            message = "Session logged. Nice work."
        }
        softHintMessage = message
        softHintDismissTask?.cancel()
        softHintDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            softHintMessage = nil
        }
    }

    func refreshWeeklyDisplayFromStore() {
        objectWillChange.send()
    }

    private func bumpWeeklyMinutesToday(by minutes: Int) {
        guard minutes > 0 else { return }
        var w = weeklyMinutes
        if w.count != 7 { w = Array(repeating: 0, count: 7) }
        let idx = mondayBasedWeekdayIndex(for: Date())
        w[idx] = w[idx] + minutes
        weeklyMinutes = w
        if let data = try? encoder.encode(w) {
            defaults.set(data, forKey: Keys.weeklyMinutesJSON)
        }
    }

    private func mondayBasedWeekdayIndex(for date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        let mondayFirst = (weekday + 5) % 7
        return mondayFirst
    }

    private func weekStart(for date: Date) -> Date? {
        var cal = calendar
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps)
    }

    private func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func registerMeaningfulActivity() {
        let today = startOfDay(Date())
        if let last = lastActivityDay {
            let lastStart = startOfDay(last)
            if calendar.isDate(today, inSameDayAs: lastStart) {
                persistStreak()
                return
            }

            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               calendar.isDate(lastStart, inSameDayAs: yesterday) {
                streakDays = max(1, streakDays + 1)
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        lastActivityDay = today
        persistStreak()
    }

    private func persistStreak() {
        if let day = lastActivityDay {
            defaults.set(day.timeIntervalSince1970, forKey: Keys.lastActivityDay)
        } else {
            defaults.removeObject(forKey: Keys.lastActivityDay)
        }
        defaults.set(streakDays, forKey: Keys.streakDays)
    }

    private func saveAchievements() {
        if let data = try? encoder.encode(achievementsUnlocked) {
            defaults.set(data, forKey: Keys.achievementsJSON)
        }
    }

    private func saveSessionHistory() {
        if let data = try? encoder.encode(sessionHistory) {
            defaults.set(data, forKey: Keys.sessionHistoryJSON)
        }
    }

    private func saveCustomPresets() {
        if let data = try? encoder.encode(customTimerPresets) {
            defaults.set(data, forKey: Keys.customTimerPresetsJSON)
        }
    }

    private func refreshAchievementMetadataIfNeeded() {
        var changed = false
        var next = achievementsUnlocked
        var newlyUnlocked: [String] = []

        for achievement in AchievementCatalog.all {
            let unlocked = achievement.isUnlocked(store: self)
            guard unlocked else { continue }
            if next[achievement.id] == nil {
                next[achievement.id] = Date()
                newlyUnlocked.append(achievement.id)
                changed = true
            }
        }

        if changed {
            achievementsUnlocked = next
            saveAchievements()
            for id in newlyUnlocked {
                NotificationCenter.default.post(name: .achievementUnlocked, object: id)
            }
        }
    }

    func sceneBecameActive(at date: Date = Date()) {
        if usageSessionStartedAt == nil {
            usageSessionStartedAt = date
            defaults.set(date.timeIntervalSince1970, forKey: Keys.usageSessionStartedAt)
        }
    }

    func sceneResignedActive(at date: Date = Date()) {
        guard let start = usageSessionStartedAt else { return }
        let delta = max(0, date.timeIntervalSince(start))
        totalAppUsageSeconds += delta
        defaults.set(totalAppUsageSeconds, forKey: Keys.totalAppUsageSeconds)
        usageSessionStartedAt = nil
        defaults.removeObject(forKey: Keys.usageSessionStartedAt)
        refreshAchievementMetadataIfNeeded()
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        if domain.isEmpty == false {
            defaults.removePersistentDomain(forName: domain)
            defaults.synchronize()
        }

        UserDefaults.standard.removePersistentDomain(forName: WidgetSnapshotKeys.suiteName)

        hasSeenOnboarding = false
        workDurationSec = 30
        restDurationSec = 15
        roundsCount = 5
        timerPrefsTouched = false
        routines = []
        routinesSelectedCategory = .strength
        sessionsCompleted = 0
        totalWorkoutMinutes = 0
        weeklyMinutes = Array(repeating: 0, count: 7)
        workoutsCompleted = 0
        streakDays = 0
        lastActivityDay = nil
        achievementsUnlocked = [:]
        totalAppUsageSeconds = 0
        usageSessionStartedAt = nil
        sessionHistory = []
        customTimerPresets = []
        weeklyGoalMinutes = 150
        softHintMessage = nil

        NotificationCenter.default.post(name: .dataReset, object: nil)
        pushWidgetSnapshot()
    }
}
