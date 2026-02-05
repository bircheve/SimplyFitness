import Foundation

// MARK: - Mock Exercise Data

/// Static exercise data for development and testing
struct MockExercises {
    private init() {}

    // MARK: - Strength Exercises

    /// Upper body strength exercises
    static let upperBodyStrength: [Exercise] = [
        .strength(StrengthExercise(
            name: "Push-ups",
            instructions: "Lower chest to ground, push back up to starting position.",
            equipment: .bodyweight,
            muscleGroups: [.chest, .triceps, .shoulders],
            sets: [
                ExerciseSet(reps: 15, restTime: 60),
                ExerciseSet(reps: 12, restTime: 60),
                ExerciseSet(reps: 10, restTime: 90)
            ]
        )),
        .strength(StrengthExercise(
            name: "Dumbbell Bench Press",
            instructions: "Lie on bench, press dumbbells up and together, lower with control.",
            equipment: .dumbbells,
            muscleGroups: [.chest, .triceps, .shoulders],
            sets: [
                ExerciseSet(reps: 12, weight: 25.0, restTime: 60),
                ExerciseSet(reps: 10, weight: 27.5, restTime: 60),
                ExerciseSet(reps: 8, weight: 30.0, restTime: 90)
            ]
        )),
        .strength(StrengthExercise(
            name: "Pull-ups",
            instructions: "Hang from bar, pull body up until chin clears bar, lower with control.",
            equipment: .pullupBar,
            muscleGroups: [.back, .biceps],
            sets: [
                ExerciseSet(reps: 8, restTime: 90),
                ExerciseSet(reps: 6, restTime: 90),
                ExerciseSet(reps: 5, restTime: 120)
            ]
        )),
        .strength(StrengthExercise(
            name: "Dumbbell Rows",
            instructions: "Bend forward, pull dumbbells to sides, squeeze shoulder blades.",
            equipment: .dumbbells,
            muscleGroups: [.back, .biceps],
            sets: [
                ExerciseSet(reps: 12, weight: 20.0, restTime: 60),
                ExerciseSet(reps: 12, weight: 22.5, restTime: 60),
                ExerciseSet(reps: 10, weight: 25.0, restTime: 90)
            ]
        ))
    ]

    /// Lower body strength exercises
    static let lowerBodyStrength: [Exercise] = [
        .strength(StrengthExercise(
            name: "Bodyweight Squats",
            instructions: "Lower into squat position, return to standing.",
            equipment: .bodyweight,
            muscleGroups: [.quadriceps, .glutes],
            sets: [
                ExerciseSet(reps: 20, restTime: 60),
                ExerciseSet(reps: 18, restTime: 60),
                ExerciseSet(reps: 15, restTime: 90)
            ]
        )),
        .strength(StrengthExercise(
            name: "Lunges",
            instructions: "Step forward into lunge position, alternate legs.",
            equipment: .bodyweight,
            muscleGroups: [.quadriceps, .glutes, .hamstrings],
            sets: [
                ExerciseSet(reps: 12, restTime: 60), // 12 per leg
                ExerciseSet(reps: 10, restTime: 60),
                ExerciseSet(reps: 8, restTime: 90)
            ]
        )),
        .strength(StrengthExercise(
            name: "Calf Raises",
            instructions: "Rise up on toes, lower back down with control.",
            equipment: .bodyweight,
            muscleGroups: [.calves],
            sets: [
                ExerciseSet(reps: 20, restTime: 45),
                ExerciseSet(reps: 20, restTime: 45),
                ExerciseSet(reps: 15, restTime: 60)
            ]
        ))
    ]

    /// Core strength exercises
    static let coreStrength: [Exercise] = [
        .strength(StrengthExercise(
            name: "Russian Twists",
            instructions: "Rotate torso side to side while seated.",
            equipment: .bodyweight,
            muscleGroups: [.obliques, .core],
            sets: [
                ExerciseSet(reps: 20, restTime: 45), // Count each side
                ExerciseSet(reps: 20, restTime: 45),
                ExerciseSet(reps: 15, restTime: 60)
            ]
        )),
        .strength(StrengthExercise(
            name: "Bicycle Crunches",
            instructions: "Alternate bringing opposite elbow to knee.",
            equipment: .bodyweight,
            muscleGroups: [.abs, .obliques],
            sets: [
                ExerciseSet(reps: 24, restTime: 45), // 12 per side
                ExerciseSet(reps: 20, restTime: 45),
                ExerciseSet(reps: 16, restTime: 60)
            ]
        ))
    ]

    // MARK: - Time-Based Exercises

    /// Cardio exercises
    static let cardioExercises: [Exercise] = [
        .timeBased(TimeBasedExercise(
            name: "Jump Rope",
            instructions: "Light on feet, steady rhythm, keep elbows close to body.",
            equipment: .jumpRope,
            muscleGroups: [.cardio, .calves],
            duration: 180
        )),
        .timeBased(TimeBasedExercise(
            name: "Burpees",
            instructions: "Full body movement: squat, jump back, push-up, jump forward, jump up.",
            equipment: .none,
            muscleGroups: [.fullBody, .cardio],
            duration: 120
        )),
        .timeBased(TimeBasedExercise(
            name: "Mountain Climbers",
            instructions: "In plank position, alternate bringing knees to chest rapidly.",
            equipment: .none,
            muscleGroups: [.core, .cardio],
            duration: 90
        )),
        .timeBased(TimeBasedExercise(
            name: "High Knees",
            instructions: "Run in place bringing knees up to hip level.",
            equipment: .none,
            muscleGroups: [.cardio, .legs],
            duration: 60
        ))
    ]

    /// Warmup exercises
    static let warmupExercises: [Exercise] = [
        .timeBased(TimeBasedExercise(
            name: "Arm Circles",
            instructions: "Large circular motions with arms to warm up shoulders.",
            equipment: .none,
            muscleGroups: [.shoulders],
            duration: 60
        )),
        .timeBased(TimeBasedExercise(
            name: "Dynamic Leg Swings",
            instructions: "Swing legs forward and back to warm up hips.",
            equipment: .none,
            muscleGroups: [.legs],
            duration: 120
        )),
        .timeBased(TimeBasedExercise(
            name: "Light Jogging in Place",
            instructions: "Gentle jogging motion to warm up the body.",
            equipment: .none,
            muscleGroups: [.cardio],
            duration: 120
        )),
        .timeBased(TimeBasedExercise(
            name: "Jumping Jacks",
            instructions: "Jump while spreading legs and raising arms overhead.",
            equipment: .none,
            muscleGroups: [.fullBody],
            duration: 90
        ))
    ]

    /// Cooldown/stretching exercises
    static let cooldownExercises: [Exercise] = [
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
        )),
        .timeBased(TimeBasedExercise(
            name: "Shoulder Stretch",
            instructions: "Cross arm across body and gently pull with other arm.",
            equipment: .none,
            duration: 30
        )),
        .timeBased(TimeBasedExercise(
            name: "Child's Pose",
            instructions: "Kneel back onto heels, stretch arms forward.",
            equipment: .mat,
            duration: 90
        )),
        .timeBased(TimeBasedExercise(
            name: "Cat-Cow Stretch",
            instructions: "Alternate between arching and rounding your back.",
            equipment: .mat,
            muscleGroups: [.core],
            duration: 60
        ))
    ]

    /// Core stability exercises
    static let coreStability: [Exercise] = [
        .timeBased(TimeBasedExercise(
            name: "Plank",
            instructions: "Hold straight body position, engage core, breathe steadily.",
            equipment: .mat,
            muscleGroups: [.core, .abs],
            duration: 60
        )),
        .timeBased(TimeBasedExercise(
            name: "Side Plank",
            instructions: "Hold side plank position, keep body straight.",
            equipment: .mat,
            muscleGroups: [.obliques, .core],
            duration: 30
        ))
    ]

    // MARK: - Exercise Collections

    /// All strength exercises
    static let allStrength = upperBodyStrength + lowerBodyStrength + coreStrength

    /// All time-based exercises
    static let allTimeBased = cardioExercises + warmupExercises + cooldownExercises + coreStability

    /// All exercises
    static let all = allStrength + allTimeBased

    /// Exercises by equipment type
    static let bodyweightOnly = all.filter { $0.equipment == .bodyweight || $0.equipment == .none }
    static let needsEquipment = all.filter { $0.equipment != .bodyweight && $0.equipment != .none }
    static let dumbbellExercises = all.filter { $0.equipment == .dumbbells }
    static let matExercises = all.filter { $0.equipment == .mat }

    /// Exercises by muscle group
    static let chestExercises = all.filter { $0.muscleGroups.contains(.chest) }
    static let backExercises = all.filter { $0.muscleGroups.contains(.back) }
    static let legExercises = all.filter {
        $0.muscleGroups.contains(.legs) ||
        $0.muscleGroups.contains(.quadriceps) ||
        $0.muscleGroups.contains(.glutes)
    }
    static let coreExercises = all.filter {
        $0.muscleGroups.contains(.core) ||
        $0.muscleGroups.contains(.abs)
    }

    /// Exercises by difficulty/intensity
    static let beginnerFriendly = [
        upperBodyStrength.first!, // Push-ups can be modified
        lowerBodyStrength.first!, // Bodyweight squats
        coreStability.first!,     // Plank
        warmupExercises[2],       // Light jogging
        cooldownExercises.last!   // Cat-cow stretch
    ]

    static let intermediate = [
        upperBodyStrength[1], // Dumbbell bench press
        upperBodyStrength[3], // Dumbbell rows
        lowerBodyStrength[1], // Lunges
        cardioExercises[2],   // Mountain climbers
        coreStrength[0]       // Russian twists
    ]

    static let advanced = [
        upperBodyStrength[2], // Pull-ups
        cardioExercises[1],   // Burpees
        coreStrength[1]       // Bicycle crunches
    ]

    /// Exercises by workout section
    static let warmups = warmupExercises
    static let mainWorkout = allStrength + cardioExercises + coreStability
    static let cooldowns = cooldownExercises

    /// Default exercise for single-exercise testing
    static let `default` = upperBodyStrength.first!
}

// MARK: - Exercise Extensions for Testing

extension Exercise {
    /// Create a test strength exercise
    static func testStrengthExercise(
        name: String = "Test Exercise",
        equipment: Equipment = .bodyweight,
        muscleGroups: [MuscleGroup] = [.chest],
        sets: [ExerciseSet] = [ExerciseSet(reps: 10)]
    ) -> Exercise {
        .strength(StrengthExercise(
            name: name,
            instructions: "Test exercise instructions.",
            equipment: equipment,
            muscleGroups: muscleGroups,
            sets: sets
        ))
    }

    /// Create a test time-based exercise
    static func testTimeBasedExercise(
        name: String = "Test Exercise",
        equipment: Equipment = .none,
        muscleGroups: [MuscleGroup] = [.cardio],
        duration: TimeInterval = 60
    ) -> Exercise {
        .timeBased(TimeBasedExercise(
            name: name,
            instructions: "Test exercise instructions.",
            equipment: equipment,
            muscleGroups: muscleGroups,
            duration: duration
        ))
    }
}

// MARK: - SwiftUI Preview Helpers

#if DEBUG
import SwiftUI

extension Exercise {
    /// Exercise specifically for SwiftUI previews
    static let preview = MockExercises.default

    /// Multiple exercises for list previews
    static let previewArray = MockExercises.beginnerFriendly
}

// MARK: - Preview Provider

struct ExercisePreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Exercise Preview")
                .font(.title)
            Text("Name: \(Exercise.preview.name)")
            Text("Equipment: \(Exercise.preview.equipment.displayName)")
            Text("Muscle Groups: \(Exercise.preview.muscleGroups.map { $0.displayName }.joined(separator: ", "))")
            Text("Type: \(Exercise.preview.type.displayName)")
        }
        .padding()
    }
}
#endif