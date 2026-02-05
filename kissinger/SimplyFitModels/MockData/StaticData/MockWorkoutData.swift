import Foundation

// MARK: - Mock Workout Data

/// Static workout data for development and testing
struct MockWorkoutData {
    private init() {}

    /// Today's scheduled workout (chest, back, shoulders)
    static let todaysWorkout: WorkoutData = {
        var workout = WorkoutData(
            id: "workout-today-001",
            userId: "user-123-456-789",
            muscleGroups: [.chest, .back, .shoulders],
            sections: [
                // Warmup
                WorkoutSection(
                    type: .warmup,
                    exercises: [
                        .timeBased(TimeBasedExercise(
                            name: "Arm Circles",
                            instructions: "Large circular motions with arms to warm up shoulders.",
                            equipment: .none,
                            muscleGroups: [.shoulders],
                            duration: 60
                        )),
                        .timeBased(TimeBasedExercise(
                            name: "Light Jogging in Place",
                            instructions: "Gentle jogging motion to warm up the body.",
                            equipment: .none,
                            muscleGroups: [.cardio],
                            duration: 120
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
                        ))
                    ]
                ),
                // Cardio
                WorkoutSection(
                    type: .cardio,
                    exercises: [
                        .timeBased(TimeBasedExercise(
                            name: "Burpees",
                            instructions: "Full body movement: squat, jump back, push-up, jump forward, jump up.",
                            equipment: .none,
                            muscleGroups: [.fullBody, .cardio],
                            duration: 180
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
                            name: "Shoulder Stretch",
                            instructions: "Cross arm across body and gently pull with other arm.",
                            equipment: .none,
                            duration: 30
                        ))
                    ]
                )
            ],
            scheduledFor: Date()
        )
        return workout
    }()

    /// Yesterday's completed workout (legs)
    static let completedWorkout: WorkoutData = {
        var workout = WorkoutData(
            id: "workout-yesterday-001",
            userId: "user-123-456-789",
            muscleGroups: [.legs, .glutes],
            sections: [
                WorkoutSection(
                    type: .warmup,
                    exercises: [
                        .timeBased(TimeBasedExercise(
                            name: "Dynamic Leg Swings",
                            instructions: "Swing legs forward and back to warm up hips.",
                            equipment: .none,
                            muscleGroups: [.legs],
                            duration: 120
                        ))
                    ]
                ),
                WorkoutSection(
                    type: .main,
                    exercises: [
                        .strength(StrengthExercise(
                            name: "Bodyweight Squats",
                            instructions: "Lower into squat position, return to standing.",
                            equipment: .bodyweight,
                            muscleGroups: [.quadriceps, .glutes],
                            sets: [
                                ExerciseSet(reps: 15, restTime: 60),
                                ExerciseSet(reps: 12, restTime: 60),
                                ExerciseSet(reps: 10, restTime: 90)
                            ]
                        ))
                    ]
                ),
                WorkoutSection(
                    type: .cooldown,
                    exercises: [
                        .timeBased(TimeBasedExercise(
                            name: "Quad Stretch",
                            instructions: "Hold ankle behind you, stretch quadriceps.",
                            equipment: .none,
                            duration: 30
                        ))
                    ]
                )
            ],
            scheduledFor: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            feedback: "Legs are sore but in a good way! Felt great to get back into squats.",
            rating: 5
        )
        workout.status = .complete
        workout.completedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        return workout
    }()

    /// Tomorrow's planned core workout
    static let tomorrowsWorkout = WorkoutData(
        id: "workout-tomorrow-001",
        userId: "user-123-456-789",
        muscleGroups: [.core, .abs],
        sections: [
            WorkoutSection(
                type: .warmup,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Cat-Cow Stretch",
                        instructions: "Alternate between arching and rounding your back.",
                        equipment: .mat,
                        muscleGroups: [.core],
                        duration: 60
                    ))
                ]
            ),
            WorkoutSection(
                type: .main,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Plank",
                        instructions: "Hold straight body position, engage core.",
                        equipment: .mat,
                        muscleGroups: [.core, .abs],
                        duration: 60
                    )),
                    .strength(StrengthExercise(
                        name: "Russian Twists",
                        instructions: "Rotate torso side to side while seated.",
                        equipment: .bodyweight,
                        muscleGroups: [.obliques, .core],
                        sets: [
                            ExerciseSet(reps: 20, restTime: 45),
                            ExerciseSet(reps: 20, restTime: 45),
                            ExerciseSet(reps: 15, restTime: 60)
                        ]
                    ))
                ]
            ),
            WorkoutSection(
                type: .cooldown,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Child's Pose",
                        instructions: "Kneel back onto heels, stretch arms forward.",
                        equipment: .mat,
                        duration: 90
                    ))
                ]
            )
        ],
        scheduledFor: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    )

    /// Full body HIIT workout
    static let hiitWorkout = WorkoutData(
        id: "workout-hiit-001",
        userId: "user-123-456-789",
        muscleGroups: [.fullBody, .cardio],
        sections: [
            WorkoutSection(
                type: .warmup,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Jumping Jacks",
                        instructions: "Jump while spreading legs and raising arms overhead.",
                        equipment: .none,
                        muscleGroups: [.fullBody],
                        duration: 90
                    ))
                ]
            ),
            WorkoutSection(
                type: .main,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Mountain Climbers",
                        instructions: "In plank position, alternate bringing knees to chest rapidly.",
                        equipment: .none,
                        muscleGroups: [.core, .cardio],
                        duration: 45
                    )),
                    .timeBased(TimeBasedExercise(
                        name: "Burpees",
                        instructions: "Full body movement: squat, jump back, push-up, jump forward, jump up.",
                        equipment: .none,
                        muscleGroups: [.fullBody, .cardio],
                        duration: 45
                    )),
                    .timeBased(TimeBasedExercise(
                        name: "High Knees",
                        instructions: "Run in place bringing knees up to hip level.",
                        equipment: .none,
                        muscleGroups: [.cardio, .legs],
                        duration: 45
                    ))
                ]
            ),
            WorkoutSection(
                type: .cooldown,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Deep Breathing",
                        instructions: "Slow, controlled breathing to lower heart rate.",
                        equipment: .none,
                        duration: 120
                    ))
                ]
            )
        ],
        scheduledFor: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    )

    /// Beginner bodyweight workout
    static let beginnerWorkout = WorkoutData(
        id: "workout-beginner-001",
        userId: "user-new-999",
        muscleGroups: [.fullBody],
        sections: [
            WorkoutSection(
                type: .warmup,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Marching in Place",
                        instructions: "Gentle marching motion to warm up.",
                        equipment: .none,
                        muscleGroups: [.cardio],
                        duration: 60
                    ))
                ]
            ),
            WorkoutSection(
                type: .main,
                exercises: [
                    .strength(StrengthExercise(
                        name: "Wall Push-ups",
                        instructions: "Stand arm's length from wall, push against wall.",
                        equipment: .none,
                        muscleGroups: [.chest, .shoulders],
                        sets: [
                            ExerciseSet(reps: 8, restTime: 60),
                            ExerciseSet(reps: 8, restTime: 60)
                        ]
                    )),
                    .strength(StrengthExercise(
                        name: "Chair Squats",
                        instructions: "Sit and stand from chair without using hands.",
                        equipment: .none,
                        muscleGroups: [.legs, .glutes],
                        sets: [
                            ExerciseSet(reps: 10, restTime: 60),
                            ExerciseSet(reps: 8, restTime: 60)
                        ]
                    ))
                ]
            ),
            WorkoutSection(
                type: .cooldown,
                exercises: [
                    .timeBased(TimeBasedExercise(
                        name: "Gentle Stretching",
                        instructions: "Light full-body stretching routine.",
                        equipment: .none,
                        duration: 180
                    ))
                ]
            )
        ],
        scheduledFor: Date()
    )

    // MARK: - Convenience Arrays

    /// All sample workouts
    static let all: [WorkoutData] = [
        todaysWorkout,
        completedWorkout,
        tomorrowsWorkout,
        hiitWorkout,
        beginnerWorkout
    ]

    /// Workouts by status
    static let upcoming = [todaysWorkout, tomorrowsWorkout, hiitWorkout, beginnerWorkout]
    static let completed = [completedWorkout]
    static let scheduled = all

    /// Workouts by type
    static let strengthWorkouts = [todaysWorkout, completedWorkout, tomorrowsWorkout]
    static let cardioWorkouts = [hiitWorkout]
    static let beginnerWorkouts = [beginnerWorkout]

    /// Workouts by difficulty
    static let easy = [beginnerWorkout]
    static let moderate = [todaysWorkout, tomorrowsWorkout]
    static let challenging = [hiitWorkout]

    /// Workouts by equipment needed
    static let bodyweightOnly = [hiitWorkout, beginnerWorkout, completedWorkout]
    static let needsEquipment = [todaysWorkout, tomorrowsWorkout]

    /// Default workout for single-workout testing
    static let `default` = todaysWorkout
}

// MARK: - Workout Data Extensions for Testing

extension WorkoutData {
    /// Create a test workout with custom values
    static func testWorkout(
        userId: String = "test-user",
        muscleGroups: [MuscleGroup] = [.chest],
        scheduledFor: Date = Date(),
        status: CompletionStatus = .incomplete
    ) -> WorkoutData {
        var workout = WorkoutData(
            id: UUID().uuidString,
            userId: userId,
            muscleGroups: muscleGroups,
            sections: [
                WorkoutSection(
                    type: .warmup,
                    exercises: [.timeBased(TimeBasedExercise(
                        name: "Test Warmup",
                        instructions: "Test warmup exercise.",
                        equipment: .none,
                        duration: 60
                    ))]
                ),
                WorkoutSection(
                    type: .main,
                    exercises: [.strength(StrengthExercise(
                        name: "Test Exercise",
                        instructions: "Test main exercise.",
                        equipment: .bodyweight,
                        muscleGroups: muscleGroups,
                        sets: [ExerciseSet(reps: 10)]
                    ))]
                ),
                WorkoutSection(
                    type: .cooldown,
                    exercises: [.timeBased(TimeBasedExercise(
                        name: "Test Cooldown",
                        instructions: "Test cooldown exercise.",
                        equipment: .none,
                        duration: 60
                    ))]
                )
            ],
            scheduledFor: scheduledFor
        )
        workout.status = status
        return workout
    }

    /// Create a workout for specific muscle groups
    static func workoutForMuscleGroups(_ muscleGroups: [MuscleGroup]) -> WorkoutData {
        testWorkout(muscleGroups: muscleGroups)
    }

    /// Create a completed workout
    static func completedTestWorkout() -> WorkoutData {
        var workout = testWorkout()
        workout.status = .complete
        workout.completedAt = Date()
        workout.feedback = "Great workout!"
        workout.rating = 4
        return workout
    }

    /// Create a workout scheduled for today
    static func todaysTestWorkout() -> WorkoutData {
        testWorkout(scheduledFor: Date())
    }
}

// MARK: - SwiftUI Preview Helpers

#if DEBUG
import SwiftUI

extension WorkoutData {
    /// Workout specifically for SwiftUI previews
    static let preview = MockWorkoutData.todaysWorkout

    /// Multiple workouts for list previews
    static let previewArray = MockWorkoutData.all
}

// MARK: - Preview Provider

struct WorkoutDataPreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Text("Workout Preview")
                .font(.title)
            Text("Muscle Groups: \(WorkoutData.preview.primaryMuscleGroups.map { $0.displayName }.joined(separator: ", "))")
            Text("Duration: \(WorkoutData.preview.estimatedDurationString)")
            Text("Exercises: \(WorkoutData.preview.totalExercises)")
            Text("Status: \(WorkoutData.preview.status.displayName)")
            Text("Difficulty: \(WorkoutData.preview.difficultyLevel.displayName)")
        }
        .padding()
    }
}
#endif