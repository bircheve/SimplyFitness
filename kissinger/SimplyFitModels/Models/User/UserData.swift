import Foundation
import Combine

// MARK: - User Data

/// Extended user data including fitness preferences and story
struct UserData: DataConvertible, Validatable, ObservableData {
    let id: String
    let userId: String
    let entity: String
    let prompt: String // The user's fitness story/questionnaire response
    let fitnessLevel: FitnessLevel
    let primaryGoals: [FitnessGoal]
    let availableEquipment: [Equipment]
    let workoutFrequency: WorkoutFrequency
    let preferredWorkoutDuration: WorkoutDuration
    let fitnessExperience: FitnessExperience
    let injuries: [String]
    let preferences: FitnessPreferences
    let createdAt: Date
    let updatedAt: Date?

    // ObservableData conformance
    func refresh() {
        // Implementation for refreshing data when connected to backend
    }

    // MARK: - Computed Properties

    var hasEquipment: Bool {
        !availableEquipment.isEmpty && availableEquipment != [.none]
    }

    var canWorkoutAtHome: Bool {
        !availableEquipment.contains { $0.requiresGym }
    }

    var hasInjuries: Bool {
        !injuries.isEmpty
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case entity
        case prompt
        case fitnessLevel
        case primaryGoals
        case availableEquipment
        case workoutFrequency
        case preferredWorkoutDuration
        case fitnessExperience
        case injuries
        case preferences
        case createdAt
        case updatedAt
    }

    // MARK: - Validation

    func validate() throws {
        guard id.isNotEmpty else {
            throw ValidationError.missingRequiredField("id")
        }

        guard userId.isNotEmpty else {
            throw ValidationError.missingRequiredField("userId")
        }

        guard prompt.isNotEmpty else {
            throw ValidationError.missingRequiredField("prompt")
        }

        guard primaryGoals.count > 0 else {
            throw ValidationError.missingRequiredField("primaryGoals")
        }

        // Validate prompt length (story should be meaningful)
        try prompt.validateLength(min: 10, max: 1000)
    }
}

// MARK: - Supporting Types

@frozen
enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }

    var description: String {
        switch self {
        case .beginner:
            return "New to fitness or returning after a long break"
        case .intermediate:
            return "Regular exercise routine for 6+ months"
        case .advanced:
            return "Consistent training for 2+ years"
        }
    }
}

@frozen
enum FitnessGoal: String, CaseIterable, Codable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case strength = "strength"
    case endurance = "endurance"
    case flexibility = "flexibility"
    case generalFitness = "general_fitness"
    case athleticPerformance = "athletic_performance"
    case rehabilitation = "rehabilitation"

    var displayName: String {
        switch self {
        case .weightLoss:
            return "Weight Loss"
        case .muscleGain:
            return "Muscle Gain"
        case .strength:
            return "Strength Training"
        case .endurance:
            return "Endurance"
        case .flexibility:
            return "Flexibility"
        case .generalFitness:
            return "General Fitness"
        case .athleticPerformance:
            return "Athletic Performance"
        case .rehabilitation:
            return "Rehabilitation"
        }
    }

    var systemImageName: String {
        switch self {
        case .weightLoss:
            return "figure.run"
        case .muscleGain:
            return "figure.strengthtraining.traditional"
        case .strength:
            return "dumbbell"
        case .endurance:
            return "figure.outdoor.cycle"
        case .flexibility:
            return "figure.flexibility"
        case .generalFitness:
            return "figure.mixed.cardio"
        case .athleticPerformance:
            return "sportscourt"
        case .rehabilitation:
            return "cross.case"
        }
    }
}

@frozen
enum WorkoutFrequency: String, CaseIterable, Codable {
    case daily = "daily"
    case sixTimesPerWeek = "6_times_per_week"
    case fiveTimesPerWeek = "5_times_per_week"
    case fourTimesPerWeek = "4_times_per_week"
    case threeTimesPerWeek = "3_times_per_week"
    case twicePerWeek = "twice_per_week"
    case oncePerWeek = "once_per_week"

    var displayName: String {
        switch self {
        case .daily:
            return "Daily (7x/week)"
        case .sixTimesPerWeek:
            return "6 times per week"
        case .fiveTimesPerWeek:
            return "5 times per week"
        case .fourTimesPerWeek:
            return "4 times per week"
        case .threeTimesPerWeek:
            return "3 times per week"
        case .twicePerWeek:
            return "2 times per week"
        case .oncePerWeek:
            return "Once per week"
        }
    }

    var daysPerWeek: Int {
        switch self {
        case .daily:
            return 7
        case .sixTimesPerWeek:
            return 6
        case .fiveTimesPerWeek:
            return 5
        case .fourTimesPerWeek:
            return 4
        case .threeTimesPerWeek:
            return 3
        case .twicePerWeek:
            return 2
        case .oncePerWeek:
            return 1
        }
    }
}

@frozen
enum WorkoutDuration: String, CaseIterable, Codable {
    case fifteen = "15_minutes"
    case thirty = "30_minutes"
    case fortyfive = "45_minutes"
    case sixty = "60_minutes"
    case ninety = "90_minutes"
    case unlimited = "unlimited"

    var displayName: String {
        switch self {
        case .fifteen:
            return "15 minutes"
        case .thirty:
            return "30 minutes"
        case .fortyfive:
            return "45 minutes"
        case .sixty:
            return "60 minutes"
        case .ninety:
            return "90 minutes"
        case .unlimited:
            return "No limit"
        }
    }

    var minutes: Int? {
        switch self {
        case .fifteen:
            return 15
        case .thirty:
            return 30
        case .fortyfive:
            return 45
        case .sixty:
            return 60
        case .ninety:
            return 90
        case .unlimited:
            return nil
        }
    }
}

@frozen
enum FitnessExperience: String, CaseIterable, Codable {
    case lessThanSixMonths = "less_than_6_months"
    case sixMonthsToYear = "6_months_to_1_year"
    case oneToTwoYears = "1_to_2_years"
    case twoToFiveYears = "2_to_5_years"
    case moreThanFiveYears = "more_than_5_years"

    var displayName: String {
        switch self {
        case .lessThanSixMonths:
            return "Less than 6 months"
        case .sixMonthsToYear:
            return "6 months - 1 year"
        case .oneToTwoYears:
            return "1 - 2 years"
        case .twoToFiveYears:
            return "2 - 5 years"
        case .moreThanFiveYears:
            return "More than 5 years"
        }
    }
}

struct FitnessPreferences: Codable, Equatable {
    let preferredMuscleGroups: [MuscleGroup]
    let avoidedMuscleGroups: [MuscleGroup]
    let preferredWorkoutTypes: [WorkoutType]
    let workoutIntensity: WorkoutIntensity
    let restDayPreference: RestDayPreference
    let musicPreference: String?

    enum WorkoutType: String, CaseIterable, Codable {
        case strength = "strength"
        case cardio = "cardio"
        case hiit = "hiit"
        case yoga = "yoga"
        case pilates = "pilates"
        case crossTraining = "cross_training"
        case sports = "sports"
        case dance = "dance"

        var displayName: String {
            switch self {
            case .strength:
                return "Strength Training"
            case .cardio:
                return "Cardio"
            case .hiit:
                return "HIIT"
            case .yoga:
                return "Yoga"
            case .pilates:
                return "Pilates"
            case .crossTraining:
                return "Cross Training"
            case .sports:
                return "Sports"
            case .dance:
                return "Dance"
            }
        }
    }

    enum WorkoutIntensity: String, CaseIterable, Codable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        case variable = "variable"

        var displayName: String {
            switch self {
            case .low:
                return "Low Intensity"
            case .moderate:
                return "Moderate Intensity"
            case .high:
                return "High Intensity"
            case .variable:
                return "Variable Intensity"
            }
        }
    }

    enum RestDayPreference: String, CaseIterable, Codable {
        case none = "none"
        case activeRecovery = "active_recovery"
        case completeRest = "complete_rest"
        case flexible = "flexible"

        var displayName: String {
            switch self {
            case .none:
                return "No Rest Days"
            case .activeRecovery:
                return "Active Recovery"
            case .completeRest:
                return "Complete Rest"
            case .flexible:
                return "Flexible"
            }
        }
    }
}

// MARK: - Mock Data

extension UserData: MockDataProviding {
    static var mockData: UserData {
        UserData(
            id: "story-user-123-456-789",
            userId: "user-123-456-789",
            entity: "story",
            prompt: "I'm a 28-year-old software developer looking to build muscle and improve my overall fitness. I have dumbbells and a pull-up bar at home. I want to work out 4 times per week for about 45 minutes each session. My goal is to gain lean muscle mass and improve my strength.",
            fitnessLevel: .intermediate,
            primaryGoals: [.muscleGain, .strength, .generalFitness],
            availableEquipment: [.dumbbells, .pullupBar, .mat],
            workoutFrequency: .fourTimesPerWeek,
            preferredWorkoutDuration: .fortyfive,
            fitnessExperience: .oneToTwoYears,
            injuries: [],
            preferences: FitnessPreferences(
                preferredMuscleGroups: [.chest, .back, .shoulders],
                avoidedMuscleGroups: [],
                preferredWorkoutTypes: [.strength, .hiit],
                workoutIntensity: .moderate,
                restDayPreference: .activeRecovery,
                musicPreference: "Rock/Electronic"
            ),
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        )
    }

    static var mockDataArray: [UserData] {
        [mockData]
    }
}