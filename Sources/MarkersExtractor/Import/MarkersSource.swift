//
//  MarkersSource.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public enum MarkersSource: String {
    case markers
    case markersAndCaptions
    case captions
}

extension MarkersSource: Equatable { }

extension MarkersSource: Hashable { }

extension MarkersSource: CaseIterable { }

extension MarkersSource: Identifiable {
    public var id: Self {
        self
    }
}

extension MarkersSource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .markers: "Markers"
        case .markersAndCaptions: "Markers and Captions"
        case .captions: "Captions"
        }
    }
}

extension MarkersSource: Sendable { }

// MARK: - Properties

extension MarkersSource {
    public var includesMarkers: Bool {
        switch self {
        case .markers, .markersAndCaptions: true
        case .captions: false
        }
    }

    public var includesCaptions: Bool {
        switch self {
        case .markers: false
        case .captions, .markersAndCaptions: true
        }
    }
}
