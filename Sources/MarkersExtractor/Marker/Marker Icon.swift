import Foundation

extension Marker {
    var icon: Icon {
        switch type {
        case .standard:
            return .standard
        case let .todo(completed):
            return completed ? .completed : .todo
        case .chapter:
            return .chapter
        }
    }

    enum Icon {
        case chapter
        case completed
        case todo
        case standard

        var resource: Resource {
            switch self {
            case .chapter: return .marker_png
            case .completed: return .marker_completed_png
            case .todo: return .marker_to_do_png
            case .standard: return .marker_png
            }
        }
        
        var url: URL? {
            resource.url
        }

        var fileName: String {
            resource.fileName
        }
    }
}
