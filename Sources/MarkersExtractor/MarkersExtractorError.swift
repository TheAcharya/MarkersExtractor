import Foundation

public enum MarkersExtractorError: LocalizedError {
    case validationError(String)
    case runtimeError(String)

    public var errorDescription: String? {
        switch self {
        case .validationError(let error):
            return "Validation error: \(error)"
        case .runtimeError(let error):
            return error
        }
    }
}
