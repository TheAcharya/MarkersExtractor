public enum MarkerImageFormat: Equatable, Hashable {
    case still(Still)
    case animated(Animated)
    
    public enum Still: String, CaseIterable {
        case png
        case jpg
    }
    
    public enum Animated: String, CaseIterable {
        case gif
    }
}

extension MarkerImageFormat: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        if let match = Still(rawValue: rawValue) {
            self = .still(match)
        } else if let match = Animated(rawValue: rawValue) {
            self = .animated(match)
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case let .still(fmt):
            return fmt.rawValue
        case let .animated(fmt):
            return fmt.rawValue
        }
    }
}

extension MarkerImageFormat: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension MarkerImageFormat: CaseIterable {
    public static let allCases: [MarkerImageFormat] =
        Still.allCases.map { .still($0) }
            + Animated.allCases.map { .animated($0) }
}
