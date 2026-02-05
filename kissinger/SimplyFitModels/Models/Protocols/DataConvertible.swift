import Foundation

// MARK: - Core Data Protocols

/// Protocol for models that can be validated
protocol Validatable {
    func validate() throws
}

/// Protocol for models that can be converted to/from backend data
protocol DataConvertible: Codable, Identifiable, Equatable {
    associatedtype ID: Hashable
    var id: ID { get }
}

/// Validation errors for data models
enum ValidationError: LocalizedError {
    case missingRequiredField(String)
    case invalidValue(field: String, value: Any)
    case invalidLength(field: String, min: Int?, max: Int?)
    case invalidRange(field: String, min: Double?, max: Double?)

    var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidValue(let field, let value):
            return "Invalid value for \(field): \(value)"
        case .invalidLength(let field, let min, let max):
            var message = "Invalid length for \(field)"
            if let min = min, let max = max {
                message += " (must be between \(min) and \(max) characters)"
            } else if let min = min {
                message += " (must be at least \(min) characters)"
            } else if let max = max {
                message += " (must be no more than \(max) characters)"
            }
            return message
        case .invalidRange(let field, let min, let max):
            var message = "Invalid range for \(field)"
            if let min = min, let max = max {
                message += " (must be between \(min) and \(max))"
            } else if let min = min {
                message += " (must be at least \(min))"
            } else if let max = max {
                message += " (must be no more than \(max))"
            }
            return message
        }
    }
}

// MARK: - Mock Data Protocol

/// Protocol for models that can provide mock/sample data
protocol MockDataProviding {
    static var mockData: Self { get }
    static var mockDataArray: [Self] { get }
}

// MARK: - Observable Data Protocol

import Combine

/// Protocol for data that can be observed for changes
protocol ObservableData: ObservableObject {
    func refresh()
}