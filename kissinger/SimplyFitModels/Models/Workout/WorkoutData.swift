import Foundation
import Combine

// MARK: - Workout Data

/// Complete workout containing all sections and metadata
struct WorkoutData: DataConvertible, Validatable, ObservableData {
    let id: String
    let userId: String
    let entity: String
    let chatRole: ChatRole
    var muscleGroups: [MuscleGroup]
    var sections: [WorkoutSection]
    var status: CompletionStatus
    var gptStatus: GPTStatus
    let scheduledFor: Date
    let createdAt: Date
    var updatedAt: Date?
    var completedAt: Date?
    var feedback: String?
    var rating: Int? // 1-5 stars

    init(
        id: String = UUID().uuidString,
        userId: String,
        entity: String = "workout",
        chatRole: ChatRole = .assistant,
        muscleGroups: [MuscleGroup] = [],
        sections: [WorkoutSection] = [],
        scheduledFor: Date = Date(),
        feedback: String? = nil,
        rating: Int? = nil
    ) {
        self.id = id
        self.userId = userId
        self.entity = entity
        self.chatRole = chatRole
        self.muscleGroups = muscleGroups
        self.sections = sections
        self.status = .incomplete
        self.gptStatus = .complete
        self.scheduledFor = scheduledFor
        self.createdAt = Date()
        self.updatedAt = nil
        self.completedAt = nil
        self.feedback = feedback
        self.rating = rating
    }

    // MARK: - Computed Properties

    /// Get section by type
    func section(for type: WorkoutSectionType) -> WorkoutSection? {
        sections.first { $0.type == type }
    }

    /// Warmup section
    var warmup: WorkoutSection? {
        section(for: .warmup)
    }

    /// Main workout section
    var main: WorkoutSection? {
        section(for: .main)
    }

    /// Cardio section
    var cardio: WorkoutSection? {
        section(for: .cardio)
    }

    /// Cooldown section
    var cooldown: WorkoutSection? {
        section(for: .cooldown)
    }

    /// Total number of exercises across all sections
    var totalExercises: Int {
        sections.reduce(0) { $0 + $1.exerciseCount }
    }

    /// Number of completed exercises
    var completedExercises: Int {
        sections.reduce(0) { $0 + $1.completedExercises }
    }

    /// Overall progress percentage
    var progressPercentage: Double {
        guard totalExercises > 0 else { return 0 }
        return Double(completedExercises) / Double(totalExercises)
    }

    /// Estimated total workout duration
    var estimatedDuration: TimeInterval {
        sections.reduce(0) { $0 + $1.estimatedDuration }
    }

    /// Formatted estimated duration
    var estimatedDurationString: String {
        let minutes = Int(estimatedDuration) / 60
        if minutes > 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes) min"
        }
    }

    /// All equipment needed for this workout
    var requiredEquipment: [Equipment] {
        let allEquipment = sections.flatMap { $0.requiredEquipment }
        return Array(Set(allEquipment)).sorted { $0.displayName < $1.displayName }
    }

    /// Primary muscle groups (most frequently targeted)
    var primaryMuscleGroups: [MuscleGroup] {
        if !muscleGroups.isEmpty {
            return muscleGroups
        }

        let allMuscleGroups = sections.flatMap { $0.primaryMuscleGroups }
        let muscleGroupCounts = Dictionary(grouping: allMuscleGroups, by: { $0 })
            .mapValues { $0.count }

        return muscleGroupCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    /// Check if workout is scheduled for today
    var isScheduledForToday: Bool {
        Calendar.current.isDate(scheduledFor, inSameDayAs: Date())
    }

    /// Check if workout is overdue
    var isOverdue: Bool {
        scheduledFor < Date() && status != .complete
    }

    /// Days since scheduled
    var daysSinceScheduled: Int {
        Calendar.current.dateComponents([.day], from: scheduledFor, to: Date()).day ?? 0
    }

    /// Whether the workout can be started
    var canStart: Bool {
        gptStatus == .complete && status == .incomplete && !sections.isEmpty
    }

    /// Whether the workout is in progress
    var isInProgress: Bool {
        status == .inProgress
    }

    /// Whether the workout is completed
    var isCompleted: Bool {
        status == .complete
    }

    /// Workout difficulty level based on duration and exercises
    var difficultyLevel: WorkoutDifficulty {
        let durationMinutes = estimatedDuration / 60
        let exerciseCount = totalExercises

        if durationMinutes < 20 || exerciseCount < 5 {
            return .easy
        } else if durationMinutes < 45 || exerciseCount < 12 {
            return .moderate
        } else {
            return .challenging
        }
    }

    // MARK: - Methods

    /// Add a section to the workout
    mutating func addSection(_ section: WorkoutSection) {
        // Remove existing section of same type
        sections.removeAll { $0.type == section.type }
        // Add new section
        sections.append(section)
        // Sort sections by their natural order
        sections.sort { $0.type.sortOrder < $1.type.sortOrder }
        updateStatus()
    }

    /// Remove section by type
    mutating func removeSection(_ type: WorkoutSectionType) {
        sections.removeAll { $0.type == type }
        updateStatus()
    }

    /// Start the workout
    mutating func start() {
        guard canStart else { return }
        status = .inProgress
        updatedAt = Date()
    }

    /// Complete the workout
    mutating func complete() {
        status = .complete
        completedAt = Date()
        updatedAt = Date()
    }

    /// Skip the workout
    mutating func skip() {
        status = .skipped
        updatedAt = Date()
    }

    /// Add feedback and rating
    mutating func addFeedback(_ feedback: String, rating: Int? = nil) {
        self.feedback = feedback
        if let rating = rating, (1...5).contains(rating) {
            self.rating = rating
        }
        updatedAt = Date()
    }

    /// Update overall status based on section statuses
    mutating func updateStatus() {
        let completedSections = sections.filter { $0.isCompleted }
        let inProgressSections = sections.filter { $0.completionStatus == .inProgress }

        if completedSections.count == sections.count && !sections.isEmpty {
            status = .complete
            completedAt = Date()
        } else if inProgressSections.count > 0 || completedSections.count > 0 {
            status = .inProgress
        } else {
            status = .incomplete
        }

        updatedAt = Date()
    }

    // MARK: - ObservableData

    func refresh() {
        // Implementation for refreshing data when connected to backend
    }

    // MARK: - Validation

    func validate() throws {
        guard id.isNotEmpty else {
            throw ValidationError.missingRequiredField("id")
        }

        guard userId.isNotEmpty else {
            throw ValidationError.missingRequiredField("userId")
        }

        // Must have at least warmup, main, and cooldown
        let requiredTypes: [WorkoutSectionType] = [.warmup, .main, .cooldown]
        for requiredType in requiredTypes {
            guard sections.contains(where: { $0.type == requiredType }) else {
                throw ValidationError.missingRequiredField("section: \(requiredType.rawValue)")
            }
        }

        // Validate each section
        for section in sections {
            try section.validate()
        }

        // Validate rating if present
        if let rating = rating {
            guard (1...5).contains(rating) else {
                throw ValidationError.invalidRange(field: "rating", min: 1, max: 5)
            }
        }

        // Validate feedback length if present
        if let feedback = feedback {
            try feedback.validateLength(max: 500)
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case entity
        case chatRole
        case muscleGroups = "muscle_groups"
        case sections = "work"
        case status
        case gptStatus
        case scheduledFor
        case createdAt
        case updatedAt
        case completedAt
        case feedback
        case rating
    }
}

// MARK: - Workout Difficulty

@frozen
enum WorkoutDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case moderate = "moderate"
    case challenging = "challenging"

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .moderate:
            return "Moderate"
        case .challenging:
            return "Challenging"
        }
    }

    var color: String {
        switch self {
        case .easy:
            return "green"
        case .moderate:
            return "orange"
        case .challenging:
            return "red"
        }
    }

    var systemImageName: String {
        switch self {
        case .easy:
            return "1.circle.fill"
        case .moderate:
            return "2.circle.fill"
        case .challenging:
            return "3.circle.fill"
        }
    }
}

// MARK: - Mock Data

extension WorkoutData: MockDataProviding {
    static var mockData: WorkoutData {
        var workout = WorkoutData(
            userId: "user-123-456-789",
            muscleGroups: [.chest, .back, .shoulders],
            sections: WorkoutSection.mockDataArray,
            scheduledFor: Date(),
            feedback: "Great workout! Felt challenged but manageable.",
            rating: 4
        )
        workout.status = .complete
        workout.completedAt = Calendar.current.date(byAdding: .hour, value: -2, to: Date())
        return workout
    }

    static var mockDataArray: [WorkoutData] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today) ?? today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today

        return [
            // Today's workout
            WorkoutData(
                id: "workout-today",
                userId: "user-123-456-789",
                muscleGroups: [.chest, .back, .shoulders],
                sections: [
                    WorkoutSection.mockDataArray[0], // warmup
                    WorkoutSection.mockDataArray[1], // main
                    WorkoutSection.mockDataArray[3]  // cooldown
                ],
                scheduledFor: today
            ),

            // Yesterday's completed workout
            {
                var workout = WorkoutData(
                    id: "workout-yesterday",
                    userId: "user-123-456-789",
                    muscleGroups: [.legs, .glutes],
                    sections: [
                        WorkoutSection(
                            type: .warmup,
                            exercises: [.timeBased(TimeBasedExercise(
                                name: "Dynamic Leg Swings",
                                instructions: "Swing legs forward and back to warm up hips.",
                                equipment: .none,
                                duration: 120
                            ))]
                        ),
                        WorkoutSection(
                            type: .main,
                            exercises: [.strength(StrengthExercise(
                                name: "Bodyweight Squats",
                                instructions: "Lower into squat position, return to standing.",
                                equipment: .bodyweight,
                                muscleGroups: [.quadriceps, .glutes],
                                sets: [
                                    ExerciseSet(reps: 15),
                                    ExerciseSet(reps: 12),
                                    ExerciseSet(reps: 10)
                                ]
                            ))]
                        ),
                        WorkoutSection(
                            type: .cooldown,
                            exercises: [.timeBased(TimeBasedExercise(
                                name: "Quad Stretch",
                                instructions: "Hold ankle behind you, stretch quadriceps.",
                                equipment: .none,
                                duration: 30
                            ))]
                        )
                    ],
                    scheduledFor: yesterday,
                    feedback: "Legs are sore but in a good way!",
                    rating: 5
                )
                workout.status = .complete
                workout.completedAt = yesterday
                return workout
            }(),

            // Two days ago - skipped workout
            {
                var workout = WorkoutData(
                    id: "workout-skipped",
                    userId: "user-123-456-789",
                    muscleGroups: [.arms, .shoulders],
                    sections: WorkoutSection.mockDataArray,
                    scheduledFor: twoDaysAgo
                )
                workout.status = .skipped
                return workout
            }(),

            // Tomorrow's planned workout
            WorkoutData(
                id: "workout-tomorrow",
                userId: "user-123-456-789",
                muscleGroups: [.core, .abs],
                sections: [
                    WorkoutSection(
                        type: .warmup,
                        exercises: [.timeBased(TimeBasedExercise(
                            name: "Cat-Cow Stretch",
                            instructions: "Alternate between arching and rounding your back.",
                            equipment: .mat,
                            duration: 60
                        ))]
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
                                    ExerciseSet(reps: 20),
                                    ExerciseSet(reps: 20),
                                    ExerciseSet(reps: 15)
                                ]
                            ))
                        ]
                    ),
                    WorkoutSection(
                        type: .cooldown,
                        exercises: [.timeBased(TimeBasedExercise(
                            name: "Child's Pose",
                            instructions: "Kneel back onto heels, stretch arms forward.",
                            equipment: .mat,
                            duration: 90
                        ))]
                    )
                ],
                scheduledFor: tomorrow
            )
        ]
    }
}