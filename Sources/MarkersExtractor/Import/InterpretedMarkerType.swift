//
//  InterpretedMarkerType.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools

// https://support.apple.com/en-sg/guide/final-cut-pro/ver397279dd/mac

/// Encapsulates marker types and non-marker types that are convertible to markers.
public enum InterpretedMarkerType {
    case marker(_ configuration: FinalCutPro.FCPXML.Marker.Configuration)
    case caption
}

extension InterpretedMarkerType: Equatable { }

extension InterpretedMarkerType: Hashable { }

extension InterpretedMarkerType: Identifiable {
    public var id: Self {
        self
    }
}

extension InterpretedMarkerType: Sendable { }

// MARK: - Properties

extension InterpretedMarkerType {
    public var name: String {
        switch self {
        case let .marker(configuration):
            configuration.name
        case .caption:
            "Caption"
        }
    }
    
    public var fullName: String {
        switch self {
        case let .marker(configuration):
            "\(configuration.name) Marker"
        case .caption:
            "Caption"
        }
    }
}
