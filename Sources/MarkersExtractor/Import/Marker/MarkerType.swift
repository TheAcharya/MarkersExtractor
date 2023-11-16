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
