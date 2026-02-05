import Foundation

// MARK: - Mock User Profile Data

/// Static user profile data for development and testing
struct MockUserProfile {
    private init() {}

    /// Primary user profile for testing
    static let johnDoe = UserProfile(
        id: "user-123-456-789",
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -28, to: Date()),
        profileImageURL: nil,
        typeformFormId: "amRNm1Hx",
        createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    )

    /// Female user profile for testing different scenarios
    static let janeSmith = UserProfile(
        id: "user-987-654-321",
        email: "jane.smith@example.com",
        firstName: "Jane",
        lastName: "Smith",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -32, to: Date()),
        profileImageURL: "https://example.com/jane-avatar.jpg",
        typeformFormId: "amRNm1Hx",
        createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
    )

    /// Young user profile for testing age-based features
    static let mikeJohnson = UserProfile(
        id: "user-555-666-777",
        email: "mike.johnson@example.com",
        firstName: "Mike",
        lastName: "Johnson",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -22, to: Date()),
        profileImageURL: nil,
        typeformFormId: "amRNm1Hx",
        createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
        updatedAt: Date()
    )

    /// Older user profile for testing different age groups
    static let sarahWilson = UserProfile(
        id: "user-111-222-333",
        email: "sarah.wilson@example.com",
        firstName: "Sarah",
        lastName: "Wilson",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -45, to: Date()),
        profileImageURL: "https://example.com/sarah-avatar.jpg",
        typeformFormId: "amRNm1Hx",
        createdAt: Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date(),
        updatedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
    )

    /// New user profile for testing onboarding flows
    static let newUser = UserProfile(
        id: "user-new-999",
        email: "new.user@example.com",
        firstName: "Alex",
        lastName: "Taylor",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -26, to: Date()),
        profileImageURL: nil,
        typeformFormId: nil,
        createdAt: Date(),
        updatedAt: Date()
    )

    // MARK: - Convenience Arrays

    /// All sample user profiles
    static let all: [UserProfile] = [
        johnDoe,
        janeSmith,
        mikeJohnson,
        sarahWilson,
        newUser
    ]

    /// Profiles with completed setup
    static let established: [UserProfile] = [
        johnDoe,
        janeSmith,
        mikeJohnson,
        sarahWilson
    ]

    /// Profiles that need onboarding
    static let needsSetup: [UserProfile] = [
        newUser
    ]

    /// Profiles with profile images
    static let withImages: [UserProfile] = [
        janeSmith,
        sarahWilson
    ]

    /// Default profile for single-user testing
    static let `default` = johnDoe
}

// MARK: - User Profile Extensions for Testing

extension UserProfile {
    /// Create a test profile with custom values
    static func testProfile(
        id: String = UUID().uuidString,
        email: String = "test@example.com",
        firstName: String = "Test",
        lastName: String = "User",
        age: Int = 25
    ) -> UserProfile {
        let birthDate = Calendar.current.date(byAdding: .year, value: -age, to: Date())

        return UserProfile(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: birthDate,
            profileImageURL: nil,
            typeformFormId: "test-form",
            createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            updatedAt: Date()
        )
    }

    /// Create a profile for a specific age
    static func profileWithAge(_ age: Int) -> UserProfile {
        testProfile(age: age)
    }

    /// Create a profile with specific name
    static func profileWithName(firstName: String, lastName: String) -> UserProfile {
        testProfile(firstName: firstName, lastName: lastName)
    }
}

// MARK: - SwiftUI Preview Helpers

#if DEBUG
import SwiftUI

extension UserProfile {
    /// Profile specifically for SwiftUI previews
    static let preview = MockUserProfile.johnDoe

    /// Multiple profiles for list previews
    static let previewArray = MockUserProfile.all
}

// MARK: - Preview Provider

struct UserProfilePreview_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("User Profile Preview")
                .font(.title)
            Text("Name: \(UserProfile.preview.fullName)")
            Text("Email: \(UserProfile.preview.email)")
            Text("Age: \(UserProfile.preview.age ?? 0)")
            Text("Initials: \(UserProfile.preview.initials)")
        }
        .padding()
    }
}
#endif