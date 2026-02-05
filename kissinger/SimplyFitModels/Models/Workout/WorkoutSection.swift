import Foundation

// MARK: - Workout Section

/// Represents a section of a workout (warmup, main, cardio, cooldown)
struct WorkoutSection: DataConvertible, Validatable {
    let id: String
    let type: WorkoutSectionType
    var exercises: [Exercise]
    var isCompleted: Bool
    var completionStatus: CompletionStatus

    init(
        id: String = UUID().uuidString,
        type: WorkoutSectionType,
        exercises: [Exercise] = []
    ) {
        self.id = id
        self.type = type
        self.exercises = exercises
        self.isCompleted = false
        self.completionStatus = .incomplete
    }

    // MARK: - Computed Properties

    var exerciseCount: Int {
        exercises.count
    }

    var completedExercises: Int {
        exercises.filter { $0.isCompleted }.count
    }

    var progressPercentage: Double {
        guard exerciseCount > 0 else { return 0 }
        return Double(completedExercises) / Double(exerciseCount)
    }

    var estimatedDuration: TimeInterval {
        var totalDuration: TimeInterval = 0

        for exercise in exercises {
            switch exercise {
            case .strength(let strengthEx):
                // Estimate 45 seconds per set + rest time
                let setsTime = Double(strengthEx.sets.count) * 45
                let restTime = strengthEx.sets.compactMap { $0.restTime }.reduce(0, +)
                totalDuration += setsTime + restTime
            case .timeBased(let timeEx):
                totalDuration += timeEx.duration
            }
        }

        return totalDuration
    }

    var estimatedDurationString: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var primaryMuscleGroups: [MuscleGroup] {
        let allMuscleGroups = exercises.flatMap { $0.muscleGroups }
        let muscleGroupCounts = Dictionary(grouping: allMuscleGroups, by: { $0 })
            .mapValues { $0.count }

        return muscleGroupCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    var requiredEquipment: [Equipment] {
        Array(Set(exercises.map { $0.equipment }))
    }

    // MARK: - Methods

    mutating func addExercise(_ exercise: Exercise) {
        exercises.append(exercise)
    }

    mutating func removeExercise(withId id: String) {
        exercises.removeAll { $0.id == id }
    }

    mutating func updateCompletionStatus() {
        let completedCount = completedExercises
        let totalCount = exerciseCount

        if totalCount == 0 {
            completionStatus = .incomplete
            isCompleted = false
        } else if completedCount == 0 {
            completionStatus = .incomplete
            isCompleted = false
        } else if completedCount == totalCount {
            completionStatus = .complete
            isCompleted = true
        } else {
            completionStatus = .inProgress
            isCompleted = false
        }
    }

    // MARK: - Validation

    func validate() throws {
        guard !exercises.isEmpty else {
            throw ValidationError.missingRequiredField("exercises")
        }

        // Validate each exercise
        for exercise in exercises {
            try exercise.validate()
        }

        // Validate section-specific constraints
        switch type {
        case .warmup, .cooldown:
            // Warmup and cooldown should primarily be time-based
            let timeBasedCount = exercises.filter { exercise in
                if case .timeBased = exercise { return true }
                return false
            }.count

            if timeBasedCount < exercises.count / 2 {
                print("Warning: \(type.displayName) sections should primarily contain time-based exercises")
            }

        case .main:
            // Main section should primarily be strength-based
            let strengthCount = exercises.filter { exercise in
                if case .strength = exercise { return true }
                return false
            }.count

            if strengthCount < exercises.count / 2 {
                print("Warning: Main section should primarily contain strength exercises")
            }

        case .cardio:
            // Cardio should be time-based
            let timeBasedCount = exercises.filter { exercise in
                if case .timeBased = exercise { return true }
                return false
            }.count

            if timeBasedCount != exercises.count {
                print("Warning: Cardio section should contain only time-based exercises")
            }
        }
    }
}

// MARK: - Workout Section Type

/// Types of workout sections
@frozen
enum WorkoutSectionType: String, CaseIterable, Codable {
    case warmup = "warmup"
    case main = "main"
    case cardio = "cardio"
    case cooldown = "cooldown"

    var displayName: String {
        switch self {
        case .warmup:
            return "Warm Up"
        case .main:
            return "Main Workout"
        case .cardio:
            return "Cardio"
        case .cooldown:
            return "Cool Down"
        }
    }

    var shortName: String {
        switch self {
        case .warmup:
            return "Warm Up"
        case .main:
            return "Main"
        case .cardio:
            return "Cardio"
        case .cooldown:
            return "Cool Down"
        }
    }

    var systemImageName: String {
        switch self {
        case .warmup:
            return "figure.flexibility"
        case .main:
            return "figure.strengthtraining.traditional"
        case .cardio:
            return "figure.run"
        case .cooldown:
            return "figure.cooldown"
        }
    }

    var description: String {
        switch self {
        case .warmup:
            return "Prepare your body for the main workout"
        case .main:
            return "The primary strength training portion"
        case .cardio:
            return "Cardiovascular exercise for endurance"
        case .cooldown:
            return "Recovery and stretching exercises"
        }
    }

    var color: String {
        switch self {
        case .warmup:
            return "orange"
        case .main:
            return "blue"
        case .cardio:
            return "red"
        case .cooldown:
            return "green"
        }
    }

    /// Typical duration range for this section type
    var typicalDurationRange: ClosedRange<TimeInterval> {
        switch self {
        case .warmup:
            return 300...600 // 5-10 minutes
        case .main:
            return 1200...2400 // 20-40 minutes
        case .cardio:
            return 600...1200 // 10-20 minutes
        case .cooldown:
            return 300...600 // 5-10 minutes
        }
    }

    /// Order in which sections typically appear
    var sortOrder: Int {
        switch self {
        case .warmup:
            return 0
        case .main:
            return 1
        case .cardio:
            return 2
        case .cooldown:
            return 3
        }
    }

    /// Whether this section is required in a complete workout
    var isRequired: Bool {
        switch self {
        case .warmup, .main, .cooldown:
            return true
        case .cardio:
            return false
        }
    }

    static var orderedSections: [WorkoutSectionType] {
        allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    static var requiredSections: [WorkoutSectionType] {
        allCases.filter { $0.isRequired }
    }
}

// MARK: - Mock Data

extension WorkoutSection: MockDataProviding {
    static var mockData: WorkoutSection {
        WorkoutSection(
            type: .main,
            exercises: [
                .strength(StrengthExercise.mockDataArray[0]),
                .strength(StrengthExercise.mockDataArray[1])
            ]
        )
    }

    static var mockDataArray: [WorkoutSection] {
        [
            // Warmup
            WorkoutSection(
                type: .warmup,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Light Jogging in Place",
                        instructions: "Gentle jogging motion to warm up the body.",
                        equipment: .none,
                        duration: 120
                    )),
                    .timeBased(TimeBasedExercise(
                        name: "Arm Circles",
                        instructions: "Large circular motions with arms to warm up shoulders.",
                        equipment: .none,
                        duration: 60
                    ))
                ]
            ),

            // Main
            WorkoutSection(
                type: .main,
                exercises: [
                    .strength(StrengthExercise(
                        name: "Dumbbell Bench Press",
                        instructions: "Lie on bench, press dumbbells up and together, lower with control.",
                        equipment: .dumbbells,
                        muscleGroups: [.chest, .triceps, .shoulders],
                        sets: [
                            ExerciseSet(reps: 12, weight: 25.0),
                            ExerciseSet(reps: 10, weight: 27.5),
                            ExerciseSet(reps: 8, weight: 30.0)
                        ]
                    )),
                    .strength(StrengthExercise(
                        name: "Pull-ups",
                        instructions: "Hang from bar, pull body up until chin clears bar, lower with control.",
                        equipment: .pullupBar,
                        muscleGroups: [.back, .biceps],
                        sets: [
                            ExerciseSet(reps: 8),
                            ExerciseSet(reps: 6),
                            ExerciseSet(reps: 5)
                        ]
                    ))
                ]
            ),

            // Cardio
            WorkoutSection(
                type: .cardio,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Jump Rope",
                        instructions: "Light on feet, steady rhythm, keep elbows close to body.",
                        equipment: .jumpRope,
                        muscleGroups: [.cardio, .calves],
                        duration: 300
                    ))
                ]
            ),

            // Cooldown
            WorkoutSection(
                type: .cooldown,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Chest Stretch",
                        instructions: "Gently stretch chest muscles against a wall.",
                        equipment: .none,
                        duration: 45
                    )),
                    .timeBased(TimeBasedExercise(
                        name: "Hamstring Stretch",
                        instructions: "Seated forward fold to stretch hamstrings.",
                        equipment: .mat,
                        duration: 45
                    ))
                ]
            )
        ]
    }
}