import Foundation

public enum MarkerRole: Hashable, Equatable {
    case audio(String)
    case video(String)
}

extension MarkerRole: CustomStringConvertible {
    public var description: String {
        stringValue
    }
    
    var stringValue: String {
        switch self {
        case .audio(let string):
            return string
        case .video(let string):
            return string
        }
    }
}

extension MarkerRole {
    var isAudio: Bool {
        guard case .audio = self else {
            return false
        }
        return true
    }
    
    var isVideo: Bool {
        guard case .video = self else {
            return false
        }
        return true
    }
}
