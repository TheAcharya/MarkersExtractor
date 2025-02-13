//
//  MarkerImageFormat Animated.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension MarkerImageFormat {
    public enum Animated: String {
        case gif
    }
}

extension MarkerImageFormat.Animated: Equatable { }

extension MarkerImageFormat.Animated: Hashable { }

extension MarkerImageFormat.Animated: CaseIterable { }

extension MarkerImageFormat.Animated: Identifiable {
    public var id: Self { self }
}

extension MarkerImageFormat.Animated: Sendable { }

// MARK: - Properties

extension MarkerImageFormat.Animated {
    /// Descriptive name for UI.
    public var name: String {
        switch self {
        case .gif:
            return "Animated GIF"
        }
    }
}
