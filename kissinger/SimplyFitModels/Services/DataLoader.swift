import Foundation
import Combine

// MARK: - Data Loader Protocol

protocol DataLoading {
    func loadUserProfile() async throws -> UserProfile
    func loadUserData() async throws -> UserData
    func loadWorkouts() async throws -> [WorkoutData]
    func loadExercises() async throws -> [Exercise]
}

// MARK: - Static Data Loader

/// Loads data from local JSON files for development and testing
final class StaticDataLoader: DataLoading, ObservableObject {
    static let shared = StaticDataLoader()

    private let bundle: Bundle

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private var cache: [String: Any] = [:]

    init(bundle: Bundle = Bundle.main) {
        self.bundle = bundle
    }

    // MARK: - Public Methods

    func loadUserProfile() async throws -> UserProfile {
        try await load(UserProfile.self, fileName: "user_profile", cacheKey: "userProfile")
    }

    func loadUserData() async throws -> UserData {
        try await load(UserData.self, fileName: "user_data", cacheKey: "userData")
    }

    func loadWorkouts() async throws -> [WorkoutData] {
        try await loadArray(WorkoutData.self, fileName: "workout_data", cacheKey: "workouts")
    }

    func loadExercises() async throws -> [Exercise] {
        try await loadArray(Exercise.self, fileName: "exercises", cacheKey: "exercises")
    }

    // MARK: - Cache Methods

    func clearCache() {
        cache.removeAll()
    }

    func preloadAll() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        do {
            _ = try await loadUserProfile()
            _ = try await loadUserData()
            _ = try await loadWorkouts()
            _ = try await loadExercises()

            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                isLoading = false
            }
        }
    }

    // MARK: - Private Methods

    private func load<T: Decodable & Validatable>(
        _ type: T.Type,
        fileName: String,
        cacheKey: String
    ) async throws -> T {
        if let cached = cache[cacheKey] as? T {
            return cached
        }

        await MainActor.run {
            isLoading = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Try to load from JSON file first
        if bundle.jsonFileExists(fileName) {
            do {
                let data = try bundle.decode(type, from: fileName)
                try data.validate()
                cache[cacheKey] = data
                return data
            } catch {
                print("Failed to load \(fileName).json, falling back to mock data: \(error)")
            }
        }

        // Fallback to mock data if JSON loading fails
        if let mockDataProvider = type as? MockDataProviding.Type,
           let mockData = mockDataProvider.mockData as? T {
            try mockData.validate()
            return mockData
        }

        throw DataLoaderError.noDataAvailable(fileName)
    }

    private func loadArray<T: Decodable & Validatable>(
        _ type: T.Type,
        fileName: String,
        cacheKey: String
    ) async throws -> [T] {
        if let cached = cache[cacheKey] as? [T] {
            return cached
        }

        await MainActor.run {
            isLoading = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        // Try to load from JSON file first
        if bundle.jsonFileExists(fileName) {
            do {
                let dataArray = try bundle.decodeArray(type, from: fileName)
                // Validate each item
                for item in dataArray {
                    try item.validate()
                }
                cache[cacheKey] = dataArray
                return dataArray
            } catch {
                print("Failed to load \(fileName).json, falling back to mock data: \(error)")
            }
        }

        // Fallback to mock data if JSON loading fails
        if let mockDataProvider = type as? MockDataProviding.Type,
           let mockDataArray = mockDataProvider.mockDataArray as? [T] {
            // Validate each item
            for item in mockDataArray {
                try item.validate()
            }
            return mockDataArray
        }

        throw DataLoaderError.noDataAvailable(fileName)
    }
}

// MARK: - Network Data Loader

/// Future implementation for loading data from API
final class NetworkDataLoader: DataLoading {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func loadUserProfile() async throws -> UserProfile {
        // TODO: Implement API call
        throw DataLoaderError.networkNotImplemented
    }

    func loadUserData() async throws -> UserData {
        // TODO: Implement API call
        throw DataLoaderError.networkNotImplemented
    }

    func loadWorkouts() async throws -> [WorkoutData] {
        // TODO: Implement API call
        throw DataLoaderError.networkNotImplemented
    }

    func loadExercises() async throws -> [Exercise] {
        // TODO: Implement API call
        throw DataLoaderError.networkNotImplemented
    }
}

// MARK: - Data Repository

/// Manages data loading with caching and error handling
@MainActor
final class DataRepository: ObservableObject {
    static let shared = DataRepository()

    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var userData: UserData?
    @Published private(set) var workouts: [WorkoutData] = []
    @Published private(set) var exercises: [Exercise] = []

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let dataLoader: DataLoading

    init(dataLoader: DataLoading = StaticDataLoader.shared) {
        self.dataLoader = dataLoader
    }

    // MARK: - Load Methods

    func loadUserProfile() async {
        isLoading = true
        error = nil

        do {
            userProfile = try await dataLoader.loadUserProfile()
        } catch {
            self.error = error
            print("Failed to load user profile: \(error)")
        }

        isLoading = false
    }

    func loadUserData() async {
        isLoading = true
        error = nil

        do {
            userData = try await dataLoader.loadUserData()
        } catch {
            self.error = error
            print("Failed to load user data: \(error)")
        }

        isLoading = false
    }

    func loadWorkouts() async {
        isLoading = true
        error = nil

        do {
            workouts = try await dataLoader.loadWorkouts()
        } catch {
            self.error = error
            print("Failed to load workouts: \(error)")
        }

        isLoading = false
    }

    func loadExercises() async {
        isLoading = true
        error = nil

        do {
            exercises = try await dataLoader.loadExercises()
        } catch {
            self.error = error
            print("Failed to load exercises: \(error)")
        }

        isLoading = false
    }

    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadUserProfile() }
            group.addTask { await self.loadUserData() }
            group.addTask { await self.loadWorkouts() }
            group.addTask { await self.loadExercises() }
        }
    }

    // MARK: - Convenience Methods

    func todaysWorkout() -> WorkoutData? {
        workouts.first { $0.isScheduledForToday }
    }

    func completedWorkouts() -> [WorkoutData] {
        workouts.filter { $0.isCompleted }
    }

    func upcomingWorkouts() -> [WorkoutData] {
        workouts.filter { $0.scheduledFor > Date() && $0.status == .incomplete }
    }

    func workoutsForMuscleGroup(_ muscleGroup: MuscleGroup) -> [WorkoutData] {
        workouts.filter { $0.primaryMuscleGroups.contains(muscleGroup) }
    }

    func exercisesForEquipment(_ equipment: Equipment) -> [Exercise] {
        exercises.filter { $0.equipment == equipment }
    }
}

// MARK: - Data Loader Errors

enum DataLoaderError: LocalizedError {
    case noDataAvailable(String)
    case networkNotImplemented
    case invalidData(String)

    var errorDescription: String? {
        switch self {
        case .noDataAvailable(let fileName):
            return "No data available for \(fileName)"
        case .networkNotImplemented:
            return "Network data loading not implemented yet"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        }
    }
}