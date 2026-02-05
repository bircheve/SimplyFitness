import Foundation

// MARK: - Completion Status

/// Status of a workout or exercise completion
@frozen
enum CompletionStatus: String, CaseIterable, Codable {
    case incomplete = "incomplete"
    case skipped = "skipped"
    case inProgress = "in_progress"
    case complete = "complete"

    var displayName: String {
        switch self {
        case .incomplete:
            return "Not Started"
        case .skipped:
            return "Skipped"
        case .inProgress:
            return "In Progress"
        case .complete:
            return "Completed"
        }
    }

    var systemImageName: String {
        switch self {
        case .incomplete:
            return "circle"
        case .skipped:
            return "xmark.circle"
        case .inProgress:
            return "clock.circle"
        case .complete:
            return "checkmark.circle.fill"
        }
    }

    var isCompleted: Bool {
        self == .complete
    }
}

// MARK: - GPT Status

/// Status of OpenAI workout generation
@frozen
enum GPTStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case complete = "complete"
    case error = "error"

    var displayName: String {
        switch self {
        case .pending:
            return "Generating..."
        case .complete:
            return "Ready"
        case .error:
            return "Error"
        }
    }

    var systemImageName: String {
        switch self {
        case .pending:
            return "hourglass"
        case .complete:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Chat Role

/// Role in chat conversation with AI
@frozen
enum ChatRole: String, CaseIterable, Codable {
    case assistant = "assistant"
    case system = "system"
    case user = "user"

    var displayName: String {
        switch self {
        case .assistant:
            return "AI Trainer"
        case .system:
            return "System"
        case .user:
            return "You"
        }
    }
}