import Foundation

// MARK: - Exercise Protocol

/// Base protocol for all exercises
protocol ExerciseProtocol: DataConvertible, Validatable {
    var name: String { get }
    var instructions: String { get }
    var equipment: Equipment { get }
    var muscleGroups: [MuscleGroup] { get }
    var isCompleted: Bool { get set }
    var completionStatus: CompletionStatus { get set }
}

// MARK: - Exercise Set

/// Represents a set of reps for strength-based exercises
struct ExerciseSet: DataConvertible, Validatable {
    let id: String
    let reps: Int
    var actualReps: Int?
    var weight: Double?
    var isCompleted: Bool
    var restTime: TimeInterval?

    init(id: String = UUID().uuidString, reps: Int, weight: Double? = nil, restTime: TimeInterval? = nil) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.actualReps = nil
        self.isCompleted = false
    }

    // MARK: - Validation

    func validate() throws {
        guard reps > 0 else {
            throw ValidationError.invalidRange(field: "reps", min: 1, max: nil)
        }

        if let weight = weight {
            guard weight >= 0 else {
                throw ValidationError.invalidRange(field: "weight", min: 0, max: nil)
            }
        }

        if let actualReps = actualReps {
            guard actualReps >= 0 else {
                throw ValidationError.invalidRange(field: "actualReps", min: 0, max: nil)
            }
        }
    }
}

// MARK: - Strength Exercise

/// Exercise performed for a set number of reps
struct StrengthExercise: ExerciseProtocol {
    let id: String
    let name: String
    let instructions: String
    let equipment: Equipment
    let muscleGroups: [MuscleGroup]
    var sets: [ExerciseSet]
    var isCompleted: Bool
    var completionStatus: CompletionStatus
    let notes: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        instructions: String,
        equipment: Equipment,
        muscleGroups: [MuscleGroup],
        sets: [ExerciseSet],
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.equipment = equipment
        self.muscleGroups = muscleGroups
        self.sets = sets
        self.notes = notes
        self.isCompleted = false
        self.completionStatus = .incomplete
    }

    // Computed properties
    var totalSets: Int {
        sets.count
    }

    var completedSets: Int {
        sets.filter { $0.isCompleted }.count
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var actualTotalReps: Int {
        sets.compactMap { $0.actualReps }.reduce(0, +)
    }

    var progressPercentage: Double {
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }

    // MARK: - Validation

    func validate() throws {
        guard name.isNotEmpty else {
            throw ValidationError.missingRequiredField("name")
        }

        guard instructions.isNotEmpty else {
            throw ValidationError.missingRequiredField("instructions")
        }

        try instructions.validateLength(max: 200)

        guard !muscleGroups.isEmpty else {
            throw ValidationError.missingRequiredField("muscleGroups")
        }

        guard !sets.isEmpty else {
            throw ValidationError.missingRequiredField("sets")
        }

        // Validate each set
        for set in sets {
            try set.validate()
        }
    }
}

// MARK: - Time-Based Exercise

/// Exercise performed for a set duration
struct TimeBasedExercise: ExerciseProtocol {
    let id: String
    let name: String
    let instructions: String
    let equipment: Equipment
    let muscleGroups: [MuscleGroup]
    let duration: TimeInterval // Duration in seconds
    var actualDuration: TimeInterval?
    var isCompleted: Bool
    var completionStatus: CompletionStatus
    let notes: String?

    init(
        id: String = UUID().uuidString,
        name: String,
        instructions: String,
        equipment: Equipment,
        muscleGroups: [MuscleGroup] = [],
        duration: TimeInterval,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.equipment = equipment
        self.muscleGroups = muscleGroups
        self.duration = duration
        self.notes = notes
        self.actualDuration = nil
        self.isCompleted = false
        self.completionStatus = .incomplete
    }

    // Computed properties
    var durationInMinutes: Double {
        duration / 60
    }

    var actualDurationInMinutes: Double? {
        guard let actualDuration = actualDuration else { return nil }
        return actualDuration / 60
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var formattedActualDuration: String? {
        guard let actualDuration = actualDuration else { return nil }
        return formatTime(actualDuration)
    }

    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Validation

    func validate() throws {
        guard name.isNotEmpty else {
            throw ValidationError.missingRequiredField("name")
        }

        guard instructions.isNotEmpty else {
            throw ValidationError.missingRequiredField("instructions")
        }

        try instructions.validateLength(max: 200)

        guard duration > 0 else {
            throw ValidationError.invalidRange(field: "duration", min: 1, max: nil)
        }

        if let actualDuration = actualDuration {
            guard actualDuration >= 0 else {
                throw ValidationError.invalidRange(field: "actualDuration", min: 0, max: nil)
            }
        }
    }
}

// MARK: - Exercise Type Enum

/// Discriminates between different exercise types
enum ExerciseType: String, CaseIterable, Codable {
    case strength = "strength"
    case timeBased = "time_based"

    var displayName: String {
        switch self {
        case .strength:
            return "Strength"
        case .timeBased:
            return "Time-based"
        }
    }
}

// MARK: - Exercise Wrapper

/// Wrapper to handle different exercise types in collections
enum Exercise: DataConvertible, Validatable {
    case strength(StrengthExercise)
    case timeBased(TimeBasedExercise)

    // Common properties
    var id: String {
        switch self {
        case .strength(let exercise):
            return exercise.id
        case .timeBased(let exercise):
            return exercise.id
        }
    }

    var name: String {
        switch self {
        case .strength(let exercise):
            return exercise.name
        case .timeBased(let exercise):
            return exercise.name
        }
    }

    var instructions: String {
        switch self {
        case .strength(let exercise):
            return exercise.instructions
        case .timeBased(let exercise):
            return exercise.instructions
        }
    }

    var equipment: Equipment {
        switch self {
        case .strength(let exercise):
            return exercise.equipment
        case .timeBased(let exercise):
            return exercise.equipment
        }
    }

    var muscleGroups: [MuscleGroup] {
        switch self {
        case .strength(let exercise):
            return exercise.muscleGroups
        case .timeBased(let exercise):
            return exercise.muscleGroups
        }
    }

    var isCompleted: Bool {
        switch self {
        case .strength(let exercise):
            return exercise.isCompleted
        case .timeBased(let exercise):
            return exercise.isCompleted
        }
    }

    var completionStatus: CompletionStatus {
        switch self {
        case .strength(let exercise):
            return exercise.completionStatus
        case .timeBased(let exercise):
            return exercise.completionStatus
        }
    }

    var type: ExerciseType {
        switch self {
        case .strength:
            return .strength
        case .timeBased:
            return .timeBased
        }
    }

    // MARK: - Validation

    func validate() throws {
        switch self {
        case .strength(let exercise):
            try exercise.validate()
        case .timeBased(let exercise):
            try exercise.validate()
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ExerciseType.self, forKey: .type)

        switch type {
        case .strength:
            let exercise = try container.decode(StrengthExercise.self, forKey: .data)
            self = .strength(exercise)
        case .timeBased:
            let exercise = try container.decode(TimeBasedExercise.self, forKey: .data)
            self = .timeBased(exercise)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)

        switch self {
        case .strength(let exercise):
            try container.encode(exercise, forKey: .data)
        case .timeBased(let exercise):
            try container.encode(exercise, forKey: .data)
        }
    }
}

// MARK: - Mock Data

extension ExerciseSet: MockDataProviding {
    static var mockData: ExerciseSet {
        ExerciseSet(reps: 12, weight: 25.0, restTime: 60)
    }

    static var mockDataArray: [ExerciseSet] {
        [
            ExerciseSet(reps: 12, weight: 25.0, restTime: 60),
            ExerciseSet(reps: 10, weight: 25.0, restTime: 60),
            ExerciseSet(reps: 8, weight: 25.0, restTime: 90)
        ]
    }
}

extension StrengthExercise: MockDataProviding {
    static var mockData: StrengthExercise {
        StrengthExercise(
            name: "Dumbbell Bench Press",
            instructions: "Lie on bench, press dumbbells up and together, lower with control.",
            equipment: .dumbbells,
            muscleGroups: [.chest, .triceps, .shoulders],
            sets: ExerciseSet.mockDataArray
        )
    }

    static var mockDataArray: [StrengthExercise] {
        [
            StrengthExercise(
                name: "Dumbbell Bench Press",
                instructions: "Lie on bench, press dumbbells up and together, lower with control.",
                equipment: .dumbbells,
                muscleGroups: [.chest, .triceps, .shoulders],
                sets: [
                    ExerciseSet(reps: 12, weight: 25.0),
                    ExerciseSet(reps: 10, weight: 27.5),
                    ExerciseSet(reps: 8, weight: 30.0)
                ]
            ),
            StrengthExercise(
                name: "Dumbbell Rows",
                instructions: "Bend forward, pull dumbbells to sides, squeeze shoulder blades.",
                equipment: .dumbbells,
                muscleGroups: [.back, .biceps],
                sets: [
                    ExerciseSet(reps: 12, weight: 20.0),
                    ExerciseSet(reps: 12, weight: 22.5),
                    ExerciseSet(reps: 10, weight: 25.0)
                ]
            )
        ]
    }
}

extension TimeBasedExercise: MockDataProviding {
    static var mockData: TimeBasedExercise {
        TimeBasedExercise(
            name: "Plank",
            instructions: "Hold straight body position, engage core, breathe steadily.",
            equipment: .mat,
            muscleGroups: [.core, .abs],
            duration: 60
        )
    }

    static var mockDataArray: [TimeBasedExercise] {
        [
            TimeBasedExercise(
                name: "Jump Rope",
                instructions: "Light on feet, steady rhythm, keep elbows close to body.",
                equipment: .jumpRope,
                muscleGroups: [.cardio, .calves],
                duration: 180
            ),
            TimeBasedExercise(
                name: "Plank",
                instructions: "Hold straight body position, engage core, breathe steadily.",
                equipment: .mat,
                muscleGroups: [.core, .abs],
                duration: 60
            )
        ]
    }
}

extension Exercise: MockDataProviding {
    static var mockData: Exercise {
        .strength(StrengthExercise.mockData)
    }

    static var mockDataArray: [Exercise] {
        [
            .strength(StrengthExercise.mockDataArray[0]),
            .timeBased(TimeBasedExercise.mockDataArray[0]),
            .strength(StrengthExercise.mockDataArray[1]),
            .timeBased(TimeBasedExercise.mockDataArray[1])
        ]
    }
}