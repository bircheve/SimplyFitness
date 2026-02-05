import Foundation

// MARK: - Equipment

/// Equipment needed for exercises
@frozen
enum Equipment: String, CaseIterable, Codable {
    // No Equipment
    case none = "none"
    case bodyweight = "bodyweight"

    // Basic Equipment
    case dumbbells = "dumbbells"
    case barbell = "barbell"
    case kettlebell = "kettlebell"
    case resistanceBands = "resistance_bands"
    case mat = "mat"

    // Cardio Equipment
    case treadmill = "treadmill"
    case bike = "bike"
    case elliptical = "elliptical"
    case jumpRope = "jump_rope"

    // Gym Equipment
    case pullupBar = "pullup_bar"
    case benchPress = "bench_press"
    case cableMachine = "cable_machine"
    case smithMachine = "smith_machine"
    case legPress = "leg_press"

    // Functional Training
    case medicineBall = "medicine_ball"
    case bosuBall = "bosu_ball"
    case stabilityBall = "stability_ball"
    case foamRoller = "foam_roller"

    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .bodyweight:
            return "Bodyweight"
        case .dumbbells:
            return "Dumbbells"
        case .barbell:
            return "Barbell"
        case .kettlebell:
            return "Kettlebell"
        case .resistanceBands:
            return "Resistance Bands"
        case .mat:
            return "Mat"
        case .treadmill:
            return "Treadmill"
        case .bike:
            return "Exercise Bike"
        case .elliptical:
            return "Elliptical"
        case .jumpRope:
            return "Jump Rope"
        case .pullupBar:
            return "Pull-up Bar"
        case .benchPress:
            return "Bench Press"
        case .cableMachine:
            return "Cable Machine"
        case .smithMachine:
            return "Smith Machine"
        case .legPress:
            return "Leg Press"
        case .medicineBall:
            return "Medicine Ball"
        case .bosuBall:
            return "BOSU Ball"
        case .stabilityBall:
            return "Stability Ball"
        case .foamRoller:
            return "Foam Roller"
        }
    }

    var category: EquipmentCategory {
        switch self {
        case .none, .bodyweight:
            return .bodyweight
        case .dumbbells, .barbell, .kettlebell:
            return .freeWeights
        case .resistanceBands, .mat, .foamRoller:
            return .accessories
        case .treadmill, .bike, .elliptical, .jumpRope:
            return .cardio
        case .pullupBar, .benchPress, .cableMachine, .smithMachine, .legPress:
            return .gymMachines
        case .medicineBall, .bosuBall, .stabilityBall:
            return .functional
        }
    }

    var systemImageName: String {
        switch self {
        case .none, .bodyweight:
            return "figure.strengthtraining.traditional"
        case .dumbbells:
            return "dumbbell"
        case .barbell:
            return "figure.strengthtraining.traditional"
        case .kettlebell:
            return "figure.strengthtraining.functional"
        case .resistanceBands:
            return "figure.flexibility"
        case .mat:
            return "figure.yoga"
        case .treadmill:
            return "figure.run"
        case .bike:
            return "figure.indoor.cycle"
        case .elliptical:
            return "figure.elliptical"
        case .jumpRope:
            return "figure.jumprope"
        case .pullupBar:
            return "figure.pull.ups"
        case .benchPress:
            return "figure.strengthtraining.traditional"
        case .cableMachine, .smithMachine:
            return "figure.strengthtraining.functional"
        case .legPress:
            return "figure.strengthtraining.traditional"
        case .medicineBall:
            return "figure.core.training"
        case .bosuBall, .stabilityBall:
            return "figure.core.training"
        case .foamRoller:
            return "figure.roll"
        }
    }

    var requiresGym: Bool {
        category == .gymMachines
    }
}

// MARK: - Equipment Category

@frozen
enum EquipmentCategory: String, CaseIterable {
    case bodyweight = "bodyweight"
    case freeWeights = "free_weights"
    case accessories = "accessories"
    case cardio = "cardio"
    case gymMachines = "gym_machines"
    case functional = "functional"

    var displayName: String {
        switch self {
        case .bodyweight:
            return "Bodyweight"
        case .freeWeights:
            return "Free Weights"
        case .accessories:
            return "Accessories"
        case .cardio:
            return "Cardio Equipment"
        case .gymMachines:
            return "Gym Machines"
        case .functional:
            return "Functional Training"
        }
    }

    var equipment: [Equipment] {
        Equipment.allCases.filter { $0.category == self }
    }
}