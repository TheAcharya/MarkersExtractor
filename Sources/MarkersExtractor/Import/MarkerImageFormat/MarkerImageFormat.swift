//
//  MarkerImageFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

public enum MarkerImageFormat {
    case still(Still)
    case animated(Animated)
}

extension MarkerImageFormat: Equatable { }

extension MarkerImageFormat: Hashable { }

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
    public var id: Self { self }
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

extension MarkerImageFormat: Sendable { }

// MARK: - Properties

extension MarkerImageFormat {
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
