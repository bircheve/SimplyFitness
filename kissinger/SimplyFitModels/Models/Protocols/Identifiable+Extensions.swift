import Foundation

// MARK: - Identifiable Extensions

extension Identifiable where Self: Hashable {
    /// Provides a stable hash value based on the ID
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Array where Element: Identifiable {
    /// Find element by ID
    func first(withID id: Element.ID) -> Element? {
        return first { $0.id == id }
    }

    /// Remove element by ID
    mutating func remove(withID id: Element.ID) {
        removeAll { $0.id == id }
    }

    /// Update or insert element
    mutating func upsert(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        } else {
            append(element)
        }
    }
}

// MARK: - Date Extensions

extension Date {
    /// ISO 8601 string representation for API compatibility
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }

    /// Create date from ISO 8601 string
    init?(iso8601String: String) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso8601String) else {
            return nil
        }
        self = date
    }
}

// MARK: - String Extensions

extension String {
    /// Validate string length
    func validateLength(min: Int? = nil, max: Int? = nil) throws {
        if let min = min, count < min {
            throw ValidationError.invalidLength(field: "string", min: min, max: max)
        }
        if let max = max, count > max {
            throw ValidationError.invalidLength(field: "string", min: min, max: max)
        }
    }

    /// Check if string is not empty
    var isNotEmpty: Bool {
        !isEmpty
    }
}