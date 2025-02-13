//
//  InterpretedMarkerType.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit

// https://support.apple.com/en-sg/guide/final-cut-pro/ver397279dd/mac

/// Encapsulates marker types and non-marker types that are convertible to markers.
public enum InterpretedMarkerType {
    case marker(_ configuration: FinalCutPro.FCPXML.Marker.Configuration)
    case caption
}

extension InterpretedMarkerType: Equatable { }

extension InterpretedMarkerType: Hashable { }

extension InterpretedMarkerType: Identifiable {
    public var id: Self { self }
}

extension InterpretedMarkerType: Sendable { }

// MARK: - Properties

extension InterpretedMarkerType {
    public var name: String {
        switch self {
        case .marker(let configuration):
            return configuration.name
        case .caption:
            return "Caption"
        }
    }
    
    public var fullName: String {
        switch self {
        case .marker(let configuration):
            return "\(configuration.name) Marker"
        case .caption:
            return "Caption"
        }
    }
}
