import Foundation

enum RoutineCategory: String, Codable, CaseIterable, Identifiable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"

    var id: String { rawValue }
}

struct RoutineExercise: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var instructions: String
    var metric: String
    var isDone: Bool
    var personalNote: String

    init(
        id: UUID = UUID(),
        name: String,
        instructions: String,
        metric: String,
        isDone: Bool = false,
        personalNote: String = ""
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.metric = metric
        self.isDone = isDone
        self.personalNote = personalNote
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, instructions, metric, isDone, personalNote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        instructions = try container.decode(String.self, forKey: .instructions)
        metric = try container.decode(String.self, forKey: .metric)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        personalNote = try container.decodeIfPresent(String.self, forKey: .personalNote) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(metric, forKey: .metric)
        try container.encode(isDone, forKey: .isDone)
        try container.encode(personalNote, forKey: .personalNote)
    }
}

struct Routine: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: RoutineCategory
    var exercises: [RoutineExercise]
    var dailyReminderNote: String

    init(
        id: UUID = UUID(),
        name: String,
        category: RoutineCategory,
        exercises: [RoutineExercise],
        dailyReminderNote: String = ""
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.exercises = exercises
        self.dailyReminderNote = dailyReminderNote
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, exercises, dailyReminderNote
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(RoutineCategory.self, forKey: .category)
        exercises = try container.decode([RoutineExercise].self, forKey: .exercises)
        dailyReminderNote = try container.decodeIfPresent(String.self, forKey: .dailyReminderNote) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(exercises, forKey: .exercises)
        try container.encode(dailyReminderNote, forKey: .dailyReminderNote)
    }

    var completionFraction: Double {
        guard exercises.isEmpty == false else { return 0 }
        let done = exercises.filter(\.isDone).count
        return Double(done) / Double(exercises.count)
    }

    var isFullyCompleted: Bool {
        exercises.isEmpty == false && exercises.allSatisfy(\.isDone)
    }
}
