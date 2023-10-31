//
//  MarkerImageFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

public enum MarkerImageFormat: Equatable, Hashable, Sendable {
    case still(Still)
    case animated(Animated)
}

extension MarkerImageFormat {
    public enum Still: String, CaseIterable, Sendable {
        case png
        case jpg
    }
}

extension MarkerImageFormat.Still: Identifiable {
    public var id: RawValue { rawValue }
}

extension MarkerImageFormat {
    public enum Animated: String, CaseIterable, Sendable {
        case gif
    }
}

extension MarkerImageFormat.Animated: Identifiable {
    public var id: RawValue { rawValue }
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

extension MarkerImageFormat: Identifiable {
    public var id: RawValue {
        switch self {
        case .still(let format):
            return "still-\(format.id)"
        case .animated(let format):
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
