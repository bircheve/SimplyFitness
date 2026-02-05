import Foundation

// MARK: - Data Validator

/// Service for validating data integrity and business rules
struct DataValidator {
    static let shared = DataValidator()

    private init() {}

    // MARK: - User Data Validation

    func validateUserProfile(_ profile: UserProfile) -> ValidationResult {
        var errors: [ValidationError] = []

        do {
            try profile.validate()
        } catch let error as ValidationError {
            errors.append(error)
        } catch {
            errors.append(ValidationError.invalidValue(field: "profile", value: "unknown"))
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    func validateUserData(_ userData: UserData) -> ValidationResult {
        var errors: [ValidationError] = []

        do {
            try userData.validate()
        } catch let error as ValidationError {
            errors.append(error)
        } catch {
            errors.append(ValidationError.invalidValue(field: "userData", value: "unknown"))
        }

        // Additional business rule validations
        if userData.primaryGoals.isEmpty {
            errors.append(ValidationError.missingRequiredField("primaryGoals"))
        }

        if userData.availableEquipment.isEmpty {
            errors.append(ValidationError.missingRequiredField("availableEquipment"))
        }

        // Check for conflicting goals
        let conflictingGoals: [(FitnessGoal, FitnessGoal)] = [
            (.weightLoss, .muscleGain),
            (.rehabilitation, .athleticPerformance)
        ]

        for (goal1, goal2) in conflictingGoals {
            if userData.primaryGoals.contains(goal1) && userData.primaryGoals.contains(goal2) {
                errors.append(ValidationError.invalidValue(
                    field: "primaryGoals",
                    value: "Conflicting goals: \(goal1.displayName) and \(goal2.displayName)"
                ))
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Workout Validation

    func validateWorkout(_ workout: WorkoutData) -> ValidationResult {
        var errors: [ValidationError] = []

        do {
            try workout.validate()
        } catch let error as ValidationError {
            errors.append(error)
        } catch {
            errors.append(ValidationError.invalidValue(field: "workout", value: "unknown"))
        }

        // Business rule validations
        validateWorkoutStructure(workout, errors: &errors)
        validateWorkoutBalance(workout, errors: &errors)
        validateWorkoutProgression(workout, errors: &errors)

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    func validateExercise(_ exercise: Exercise) -> ValidationResult {
        var errors: [ValidationError] = []

        do {
            try exercise.validate()
        } catch let error as ValidationError {
            errors.append(error)
        } catch {
            errors.append(ValidationError.invalidValue(field: "exercise", value: "unknown"))
        }

        // Exercise-specific validations
        switch exercise {
        case .strength(let strengthEx):
            validateStrengthExercise(strengthEx, errors: &errors)
        case .timeBased(let timeEx):
            validateTimeBasedExercise(timeEx, errors: &errors)
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Private Validation Methods

    private func validateWorkoutStructure(_ workout: WorkoutData, errors: inout [ValidationError]) {
        let requiredSections: [WorkoutSectionType] = [.warmup, .main, .cooldown]

        for sectionType in requiredSections {
            if workout.section(for: sectionType) == nil {
                errors.append(ValidationError.missingRequiredField("section: \(sectionType.rawValue)"))
            }
        }

        // Check section order
        let sectionTypes = workout.sections.map { $0.type }
        let expectedOrder = WorkoutSectionType.orderedSections.filter { sectionTypes.contains($0) }

        if sectionTypes != expectedOrder {
            errors.append(ValidationError.invalidValue(
                field: "sectionOrder",
                value: "Sections should be in order: \(expectedOrder.map { $0.displayName }.joined(separator: ", "))"
            ))
        }
    }

    private func validateWorkoutBalance(_ workout: WorkoutData, errors: inout [ValidationError]) {
        let totalDuration = workout.estimatedDuration
        let mainSection = workout.main

        // Check workout duration balance
        if let main = mainSection {
            let mainDuration = main.estimatedDuration
            let otherDuration = totalDuration - mainDuration

            // Main section should be at least 50% of total workout
            if mainDuration < totalDuration * 0.5 {
                errors.append(ValidationError.invalidValue(
                    field: "workoutBalance",
                    value: "Main section should be at least 50% of total workout duration"
                ))
            }

            // Warmup and cooldown shouldn't exceed 25% each
            if let warmup = workout.warmup, warmup.estimatedDuration > totalDuration * 0.25 {
                errors.append(ValidationError.invalidValue(
                    field: "warmupDuration",
                    value: "Warmup should not exceed 25% of total workout"
                ))
            }

            if let cooldown = workout.cooldown, cooldown.estimatedDuration > totalDuration * 0.25 {
                errors.append(ValidationError.invalidValue(
                    field: "cooldownDuration",
                    value: "Cooldown should not exceed 25% of total workout"
                ))
            }
        }

        // Check muscle group balance
        let muscleGroups = workout.primaryMuscleGroups
        let categories = Set(muscleGroups.map { $0.category })

        if categories.count < 2 && muscleGroups.count > 2 {
            print("Warning: Workout focuses heavily on \(categories.first?.displayName ?? "unknown") muscle groups")
        }
    }

    private func validateWorkoutProgression(_ workout: WorkoutData, errors: inout [ValidationError]) {
        // Check for logical progression in main section
        guard let mainSection = workout.main else { return }

        for exercise in mainSection.exercises {
            if case .strength(let strengthEx) = exercise {
                let sets = strengthEx.sets

                // Check for reasonable rep progression
                if sets.count > 1 {
                    let firstReps = sets.first?.reps ?? 0
                    let lastReps = sets.last?.reps ?? 0

                    // Reps should generally decrease or stay the same as weight increases
                    if lastReps > firstReps * 1.5 {
                        print("Warning: Unusual rep progression in \(strengthEx.name)")
                    }
                }

                // Check for reasonable rest times
                for set in sets {
                    if let restTime = set.restTime {
                        if restTime < 30 || restTime > 300 { // 30 seconds to 5 minutes
                            print("Warning: Unusual rest time (\(restTime)s) in \(strengthEx.name)")
                        }
                    }
                }
            }
        }
    }

    private func validateStrengthExercise(_ exercise: StrengthExercise, errors: inout [ValidationError]) {
        // Check rep ranges
        for set in exercise.sets {
            if set.reps < 1 || set.reps > 50 {
                errors.append(ValidationError.invalidRange(
                    field: "reps",
                    min: 1,
                    max: 50
                ))
            }

            if let weight = set.weight, weight < 0 {
                errors.append(ValidationError.invalidRange(
                    field: "weight",
                    min: 0,
                    max: nil
                ))
            }
        }

        // Check for appropriate muscle groups for equipment
        validateEquipmentMuscleGroupCompatibility(exercise.equipment, exercise.muscleGroups, errors: &errors)
    }

    private func validateTimeBasedExercise(_ exercise: TimeBasedExercise, errors: inout [ValidationError]) {
        // Check duration ranges
        if exercise.duration < 10 || exercise.duration > 3600 { // 10 seconds to 1 hour
            errors.append(ValidationError.invalidRange(
                field: "duration",
                min: 10,
                max: 3600
            ))
        }

        // Check for appropriate muscle groups for equipment
        validateEquipmentMuscleGroupCompatibility(exercise.equipment, exercise.muscleGroups, errors: &errors)
    }

    private func validateEquipmentMuscleGroupCompatibility(
        _ equipment: Equipment,
        _ muscleGroups: [MuscleGroup],
        errors: inout [ValidationError]
    ) {
        // Define equipment-muscle group compatibility rules
        let incompatibleCombinations: [(Equipment, MuscleGroup)] = [
            (.jumpRope, .chest),
            (.jumpRope, .back),
            (.mat, .biceps), // Mat alone typically can't target biceps effectively
        ]

        for (incompatibleEquipment, incompatibleMuscle) in incompatibleCombinations {
            if equipment == incompatibleEquipment && muscleGroups.contains(incompatibleMuscle) {
                print("Warning: \(equipment.displayName) may not be ideal for targeting \(incompatibleMuscle.displayName)")
            }
        }
    }

    // MARK: - Batch Validation

    func validateAllData(
        profile: UserProfile?,
        userData: UserData?,
        workouts: [WorkoutData],
        exercises: [Exercise]
    ) -> DataValidationResult {
        var allErrors: [String: [ValidationError]] = [:]
        var warnings: [String] = []

        // Validate user profile
        if let profile = profile {
            let profileResult = validateUserProfile(profile)
            if !profileResult.isValid {
                allErrors["userProfile"] = profileResult.errors
            }
        }

        // Validate user data
        if let userData = userData {
            let userDataResult = validateUserData(userData)
            if !userDataResult.isValid {
                allErrors["userData"] = userDataResult.errors
            }
        }

        // Validate workouts
        for (index, workout) in workouts.enumerated() {
            let workoutResult = validateWorkout(workout)
            if !workoutResult.isValid {
                allErrors["workout_\(index)"] = workoutResult.errors
            }
        }

        // Validate exercises
        for (index, exercise) in exercises.enumerated() {
            let exerciseResult = validateExercise(exercise)
            if !exerciseResult.isValid {
                allErrors["exercise_\(index)"] = exerciseResult.errors
            }
        }

        // Check for data consistency
        if let userData = userData {
            for workout in workouts {
                // Check if workout equipment matches user's available equipment
                let workoutEquipment = Set(workout.requiredEquipment)
                let userEquipment = Set(userData.availableEquipment)

                if !workoutEquipment.isSubset(of: userEquipment) {
                    let missingEquipment = workoutEquipment.subtracting(userEquipment)
                    warnings.append("Workout '\(workout.id)' requires equipment not available to user: \(missingEquipment.map { $0.displayName }.joined(separator: ", "))")
                }
            }
        }

        let isValid = allErrors.isEmpty
        return DataValidationResult(
            isValid: isValid,
            errors: allErrors,
            warnings: warnings
        )
    }
}

// MARK: - Validation Result Types

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]

    var errorMessages: [String] {
        errors.compactMap { $0.errorDescription }
    }
}

struct DataValidationResult {
    let isValid: Bool
    let errors: [String: [ValidationError]]
    let warnings: [String]

    var totalErrorCount: Int {
        errors.values.reduce(0) { $0 + $1.count }
    }

    var errorSummary: String {
        if isValid {
            return "All data is valid"
        } else {
            return "\(totalErrorCount) validation errors found across \(errors.count) data items"
        }
    }
}