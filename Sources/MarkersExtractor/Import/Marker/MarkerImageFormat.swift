//
//  MarkerImageFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

// MARK: - MarkerImageFormat

public enum MarkerImageFormat: Equatable, Hashable, Sendable {
    case still(Still)
    case animated(Animated)
    
    /// Descriptive name for UI.
    public var name: String {
        switch self {
        case let .still(format):
            return format.name
        case let .animated(format):
            return format.name
        }
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
        case let .still(format):
            return format.rawValue
        case let .animated(format):
            return format.rawValue
        }
    }
}

extension MarkerImageFormat: Identifiable {
    public var id: RawValue {
        switch self {
        case let .still(format):
            return "still-\(format.id)"
        case let .animated(format):
            return "animated-\(format.id)"
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

// MARK: - MarkerImageFormat: Still

extension MarkerImageFormat {
    public enum Still: String, CaseIterable, Sendable {
        case png
        case jpg
        
        /// Descriptive name for UI.
        public var name: String {
            switch self {
            case .png:
                return "PNG"
            case .jpg:
                return "JPEG"
            }
        }
    }
}

extension MarkerImageFormat.Still: Identifiable {
    public var id: RawValue { rawValue }
}

// MARK: - MarkerImageFormat: Animated

extension MarkerImageFormat {
    public enum Animated: String, CaseIterable, Equatable, Hashable, Sendable {
        case gif
        
        /// Descriptive name for UI.
        public var name: String {
            switch self {
            case .gif:
                return "Animated GIF"
            }
        }
    }
}

extension MarkerImageFormat.Animated: Identifiable {
    public var id: RawValue { rawValue }
}
