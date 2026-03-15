//
//  MarkerImageFormat Still.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension MarkerImageFormat {
    public enum Still: String {
        case png
        case jpg
    }
}

extension MarkerImageFormat.Still: Equatable { }

extension MarkerImageFormat.Still: Hashable { }

extension MarkerImageFormat.Still: CaseIterable { }

extension MarkerImageFormat.Still: Identifiable {
    public var id: Self {
        self
    }
}

// MARK: - Properties

extension MarkerImageFormat.Still {
    /// Descriptive name for UI.
    public var name: String {
        switch self {
        case .png:
            "PNG"
        case .jpg:
            "JPEG"
        }
    }
}

extension MarkerImageFormat.Still: Sendable { }
