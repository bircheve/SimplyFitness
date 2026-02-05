import Foundation
import Combine

// MARK: - User Profile

/// Basic user profile information
struct UserProfile: DataConvertible, Validatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let dateOfBirth: Date?
    let profileImageURL: String?
    let typeformFormId: String?
    let createdAt: Date
    let updatedAt: Date

    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }

    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.year], from: dateOfBirth, to: Date()).year
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case email
        case firstName = "given_name"
        case lastName = "family_name"
        case dateOfBirth = "birthdate"
        case profileImageURL = "picture"
        case typeformFormId = "typeform_form_id"
        case createdAt
        case updatedAt
    }

    // MARK: - Validation

    func validate() throws {
        guard id.isNotEmpty else {
            throw ValidationError.missingRequiredField("id")
        }

        guard email.isNotEmpty else {
            throw ValidationError.missingRequiredField("email")
        }

        guard firstName.isNotEmpty else {
            throw ValidationError.missingRequiredField("firstName")
        }

        guard lastName.isNotEmpty else {
            throw ValidationError.missingRequiredField("lastName")
        }

        // Validate email format
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidValue(field: "email", value: email)
        }

        // Validate name lengths
        try firstName.validateLength(min: 1, max: 50)
        try lastName.validateLength(min: 1, max: 50)

        // Validate age if date of birth is provided
        if let age = age {
            guard age >= 13 && age <= 120 else {
                throw ValidationError.invalidRange(field: "age", min: 13, max: 120)
            }
        }
    }
}

// MARK: - Mock Data

extension UserProfile: MockDataProviding {
    static var mockData: UserProfile {
        UserProfile(
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
    }

    static var mockDataArray: [UserProfile] {
        [
            UserProfile(
                id: "user-123-456-789",
                email: "john.doe@example.com",
                firstName: "John",
                lastName: "Doe",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -28, to: Date()),
                profileImageURL: nil,
                typeformFormId: "amRNm1Hx",
                createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            UserProfile(
                id: "user-987-654-321",
                email: "jane.smith@example.com",
                firstName: "Jane",
                lastName: "Smith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -32, to: Date()),
                profileImageURL: "https://example.com/jane-avatar.jpg",
                typeformFormId: "amRNm1Hx",
                createdAt: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                updatedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            UserProfile(
                id: "user-555-666-777",
                email: "mike.johnson@example.com",
                firstName: "Mike",
                lastName: "Johnson",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
                profileImageURL: nil,
                typeformFormId: "amRNm1Hx",
                createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                updatedAt: Date()
            )
        ]
    }
}