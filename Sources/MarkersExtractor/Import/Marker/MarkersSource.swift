//
//  MarkersSource.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkersSource: String, Equatable, Hashable, CaseIterable, Sendable {
    case markers
    case markersAndCaptions
    case captions
}

extension MarkersSource: Identifiable {
    public var id: Self { self }
}

extension MarkersSource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .markers: return "Markers"
        case .markersAndCaptions: return "Markers and Captions"
        case .captions: return "Captions"
        }
    }
}

extension MarkersSource {
    public var includesMarkers: Bool {
        switch self {
        case .markers, .markersAndCaptions: return true
        case .captions: return false
        }
    }
    
    public var includesCaptions: Bool {
        switch self {
        case .markers: return false
        case .captions, .markersAndCaptions: return true
        }
    }
}
