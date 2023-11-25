//
//  MarkerType.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit

// https://support.apple.com/en-sg/guide/final-cut-pro/ver397279dd/mac

extension FinalCutPro.FCPXML.Marker.MarkerType {
    public var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .toDo: return "To Do"
        }
    }
}

extension FinalCutPro.FCPXML.Marker.MarkerMetaData {
    public var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .toDo: return "To Do"
        }
    }
}

/// Encapsulates marker types and non-marker types that are convertible to markers.
public enum InterpretedMarkerType: Equatable, Hashable, Sendable {
    case marker(_ markerMetaData: FinalCutPro.FCPXML.Marker.MarkerMetaData)
    case caption
}

extension InterpretedMarkerType {
    public var name: String {
        switch self {
        case .marker(let markerMetaData):
            return markerMetaData.name
        case .caption:
            return "Caption"
        }
    }
    
    public var fullName: String {
        switch self {
        case .marker(let markerMetaData):
            return "\(markerMetaData.name) Marker"
        case .caption:
            return "Caption"
        }
    }
}
