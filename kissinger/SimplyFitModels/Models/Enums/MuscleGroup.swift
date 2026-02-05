import Foundation

// MARK: - Muscle Group

/// Muscle groups targeted by exercises
@frozen
enum MuscleGroup: String, CaseIterable, Codable {
    // Upper Body
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"

    // Core
    case abs = "abs"
    case core = "core"
    case obliques = "obliques"

    // Lower Body
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case glutes = "glutes"
    case calves = "calves"
    case legs = "legs"

    // Full Body / Compound
    case fullBody = "full_body"
    case cardio = "cardio"

    var displayName: String {
        switch self {
        case .chest:
            return "Chest"
        case .back:
            return "Back"
        case .shoulders:
            return "Shoulders"
        case .biceps:
            return "Biceps"
        case .triceps:
            return "Triceps"
        case .forearms:
            return "Forearms"
        case .abs:
            return "Abs"
        case .core:
            return "Core"
        case .obliques:
            return "Obliques"
        case .quadriceps:
            return "Quadriceps"
        case .hamstrings:
            return "Hamstrings"
        case .glutes:
            return "Glutes"
        case .calves:
            return "Calves"
        case .legs:
            return "Legs"
        case .fullBody:
            return "Full Body"
        case .cardio:
            return "Cardio"
        }
    }

    var category: MuscleGroupCategory {
        switch self {
        case .chest, .back, .shoulders, .biceps, .triceps, .forearms:
            return .upperBody
        case .abs, .core, .obliques:
            return .core
        case .quadriceps, .hamstrings, .glutes, .calves, .legs:
            return .lowerBody
        case .fullBody, .cardio:
            return .fullBody
        }
    }

    var systemImageName: String {
        switch self {
        case .chest:
            return "figure.strengthtraining.traditional"
        case .back:
            return "figure.strengthtraining.traditional"
        case .shoulders:
            return "figure.arms.open"
        case .biceps, .triceps:
            return "figure.strengthtraining.functional"
        case .forearms:
            return "hand.raised"
        case .abs, .core:
            return "figure.core.training"
        case .obliques:
            return "figure.flexibility"
        case .quadriceps, .hamstrings, .legs:
            return "figure.strengthtraining.traditional"
        case .glutes:
            return "figure.strengthtraining.traditional"
        case .calves:
            return "figure.walk"
        case .fullBody:
            return "figure.mixed.cardio"
        case .cardio:
            return "figure.run"
        }
    }
}

// MARK: - Muscle Group Category

@frozen
enum MuscleGroupCategory: String, CaseIterable {
    case upperBody = "upper_body"
    case core = "core"
    case lowerBody = "lower_body"
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .upperBody:
            return "Upper Body"
        case .core:
            return "Core"
        case .lowerBody:
            return "Lower Body"
        case .fullBody:
            return "Full Body"
        }
    }

    var muscleGroups: [MuscleGroup] {
        MuscleGroup.allCases.filter { $0.category == self }
    }
}