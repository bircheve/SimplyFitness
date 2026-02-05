import Foundation

// MARK: - Mock User Data

/// Static user data for development and testing
struct MockUserData {
    private init() {}

    /// Primary user data for John Doe
    static let johnDoeData = UserData(
        id: "story-user-123-456-789",
        userId: "user-123-456-789",
        entity: "story",
        prompt: "I'm a 28-year-old software developer looking to build muscle and improve my overall fitness. I have dumbbells and a pull-up bar at home. I want to work out 4 times per week for about 45 minutes each session. My goal is to gain lean muscle mass and improve my strength. I have a minor shoulder injury from years ago that sometimes flares up, so I need to be careful with overhead movements.",
        fitnessLevel: .intermediate,
        primaryGoals: [.muscleGain, .strength, .generalFitness],
        availableEquipment: [.dumbbells, .pullupBar, .mat],
        workoutFrequency: .fourTimesPerWeek,
        preferredWorkoutDuration: .fortyfive,
        fitnessExperience: .oneToTwoYears,
        injuries: ["Minor shoulder impingement - avoid heavy overhead pressing"],
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

    /// User data for Jane Smith (cardio focused)
    static let janeSmithData = UserData(
        id: "story-user-987-654-321",
        userId: "user-987-654-321",
        entity: "story",
        prompt: "I'm a 32-year-old marketing manager who wants to lose weight and improve my cardiovascular health. I have access to a gym but prefer working out at home. I love dance workouts and HIIT. I can dedicate 5 days a week to exercise, about 30-40 minutes per session.",
        fitnessLevel: .beginner,
        primaryGoals: [.weightLoss, .endurance, .generalFitness],
        availableEquipment: [.jumpRope, .mat, .resistanceBands],
        workoutFrequency: .fiveTimesPerWeek,
        preferredWorkoutDuration: .thirty,
        fitnessExperience: .sixMonthsToYear,
        injuries: [],
        preferences: FitnessPreferences(
            preferredMuscleGroups: [.cardio, .core, .legs],
            avoidedMuscleGroups: [],
            preferredWorkoutTypes: [.cardio, .hiit, .dance],
            workoutIntensity: .high,
            restDayPreference: .activeRecovery,
            musicPreference: "Pop/Dance"
        ),
        createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    )

    /// User data for Mike Johnson (athlete focused)
    static let mikeJohnsonData = UserData(
        id: "story-user-555-666-777",
        userId: "user-555-666-777",
        entity: "story",
        prompt: "I'm a 22-year-old college student and soccer player. I need to maintain peak athletic performance and prevent injuries. I have access to a full gym and can train 6 times per week. My focus is on functional strength, agility, and sport-specific conditioning.",
        fitnessLevel: .advanced,
        primaryGoals: [.athleticPerformance, .strength, .endurance],
        availableEquipment: [.barbell, .dumbbells, .kettlebell, .pullupBar, .medicineBall, .resistanceBands],
        workoutFrequency: .sixTimesPerWeek,
        preferredWorkoutDuration: .ninety,
        fitnessExperience: .moreThanFiveYears,
        injuries: [],
        preferences: FitnessPreferences(
            preferredMuscleGroups: [.legs, .core, .fullBody],
            avoidedMuscleGroups: [],
            preferredWorkoutTypes: [.strength, .crossTraining, .sports],
            workoutIntensity: .high,
            restDayPreference: .activeRecovery,
            musicPreference: "Hip-Hop/Electronic"
        ),
        createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
        updatedAt: Date()
    )

    /// User data for Sarah Wilson (wellness focused)
    static let sarahWilsonData = UserData(
        id: "story-user-111-222-333",
        userId: "user-111-222-333",
        entity: "story",
        prompt: "I'm a 45-year-old mother of two who wants to stay healthy and manage stress. I prefer low-impact exercises and have some knee issues. I love yoga and pilates. I can work out 3 times per week for about 45 minutes. My goal is overall wellness and maintaining flexibility.",
        fitnessLevel: .beginner,
        primaryGoals: [.flexibility, .generalFitness, .rehabilitation],
        availableEquipment: [.mat, .resistanceBands, .stabilityBall],
        workoutFrequency: .threeTimesPerWeek,
        preferredWorkoutDuration: .fortyfive,
        fitnessExperience: .lessThanSixMonths,
        injuries: ["Mild knee osteoarthritis - avoid high-impact exercises"],
        preferences: FitnessPreferences(
            preferredMuscleGroups: [.core, .back, .shoulders],
            avoidedMuscleGroups: [],
            preferredWorkoutTypes: [.yoga, .pilates],
            workoutIntensity: .low,
            restDayPreference: .completeRest,
            musicPreference: "Ambient/Classical"
        ),
        createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )

    /// New user with minimal data
    static let newUserData = UserData(
        id: "story-user-new-999",
        userId: "user-new-999",
        entity: "story",
        prompt: "I'm just starting my fitness journey and want to get in better shape. I don't have much equipment but I'm motivated to begin.",
        fitnessLevel: .beginner,
        primaryGoals: [.generalFitness],
        availableEquipment: [.bodyweight],
        workoutFrequency: .threeTimesPerWeek,
        preferredWorkoutDuration: .thirty,
        fitnessExperience: .lessThanSixMonths,
        injuries: [],
        preferences: FitnessPreferences(
            preferredMuscleGroups: [],
            avoidedMuscleGroups: [],
            preferredWorkoutTypes: [.strength, .cardio],
            workoutIntensity: .moderate,
            restDayPreference: .flexible,
            musicPreference: nil
        ),
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Convenience Arrays

    /// All sample user data
    static let all: [UserData] = [
        johnDoeData,
        janeSmithData,
        mikeJohnsonData,
        sarahWilsonData,
        newUserData
    ]

    /// User data by fitness level
    static let beginners = [janeSmithData, sarahWilsonData, newUserData]
    static let intermediate = [johnDoeData]
    static let advanced = [mikeJohnsonData]

    /// User data by goal type
    static let strengthFocused = [johnDoeData, mikeJohnsonData]
    static let cardioFocused = [janeSmithData]
    static let wellnessFocused = [sarahWilsonData]
    static let generalFitness = [johnDoeData, janeSmithData, newUserData]

    /// User data by equipment availability
    static let homeWorkouts = [johnDoeData, janeSmithData, sarahWilsonData, newUserData]
    static let gymAccess = [mikeJohnsonData]

    /// User data with injuries
    static let hasInjuries = [johnDoeData, sarahWilsonData]
    static let noInjuries = [janeSmithData, mikeJohnsonData, newUserData]

    /// Default user data for single-user testing
    static let `default` = johnDoeData
}

// MARK: - User Data Extensions for Testing

extension UserData {
    /// Create test user data with custom values
    static func testData(
        userId: String = UUID().uuidString,
        fitnessLevel: FitnessLevel = .beginner,
        goals: [FitnessGoal] = [.generalFitness],
        equipment: [Equipment] = [.bodyweight],
        frequency: WorkoutFrequency = .threeTimesPerWeek
    ) -> UserData {
        UserData(
            id: UUID().uuidString,
            userId: userId,
            entity: "story",
            prompt: "Test user data for development and testing purposes.",
            fitnessLevel: fitnessLevel,
            primaryGoals: goals,
            availableEquipment: equipment,
            workoutFrequency: frequency,
            preferredWorkoutDuration: .thirty,
            fitnessExperience: .lessThanSixMonths,
            injuries: [],
            preferences: FitnessPreferences(
                preferredMuscleGroups: [],
                avoidedMuscleGroups: [],
                preferredWorkoutTypes: [.strength],
                workoutIntensity: .moderate,
                restDayPreference: .flexible,
                musicPreference: nil
            ),
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Create user data for specific fitness level
    static func dataForLevel(_ level: FitnessLevel) -> UserData {
        switch level {
        case .beginner:
            return MockUserData.beginners.first ?? MockUserData.newUserData
        case .intermediate:
            return MockUserData.johnDoeData
        case .advanced:
            return MockUserData.mikeJohnsonData
        }
    }

    /// Create user data with specific goals
    static func dataWithGoals(_ goals: [FitnessGoal]) -> UserData {
        testData(goals: goals)
    }

    /// Create user data with specific equipment
    static func dataWithEquipment(_ equipment: [Equipment]) -> UserData {
        testData(equipment: equipment)
    }
}

// MARK: - SwiftUI Preview Helpers

#if DEBUG
import SwiftUI

extension UserData {
    /// User data specifically for SwiftUI previews
    static let preview = MockUserData.johnDoeData

    /// Multiple user data for list previews
    static let previewArray = MockUserData.all
}

// MARK: - Preview Provider

struct UserDataPreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Text("User Data Preview")
                .font(.title)
            Text("Level: \(UserData.preview.fitnessLevel.displayName)")
            Text("Goals: \(UserData.preview.primaryGoals.map { $0.displayName }.joined(separator: ", "))")
            Text("Frequency: \(UserData.preview.workoutFrequency.displayName)")
            Text("Equipment: \(UserData.preview.availableEquipment.map { $0.displayName }.joined(separator: ", "))")
            Text("Has injuries: \(UserData.preview.hasInjuries ? "Yes" : "No")")
        }
        .padding()
    }
}
#endif