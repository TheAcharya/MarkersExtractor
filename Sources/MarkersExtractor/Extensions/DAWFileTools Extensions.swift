//
//  DAWFileTools Extensions.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation

extension FCPXML.ElementType {
    var name: String {
        switch self {
        // annotation
            
        case .caption: "Caption"
        case .keyword: "Keyword"
        case .marker, .chapterMarker: "Marker"
        // story
        case .sequence: "Sequence"
        case .spine: "Spine"
        // clips
        case .assetClip: "Asset"
        case .audio: "Audio"
        case .audition: "Audition"
        case .clip: "Clip"
        case .gap: "Gap"
        case .liveDrawing: "Live Drawing"
        case .mcClip: "Multicam"
        case .refClip: "Compound"
        case .syncClip: "Sync"
        case .title: "Title"
        case .transition: "Transition"
        case .video: "Video"
        // structure
        case .library: "Library"
        case .event: "Event"
        case .project: "Project"
        default:
            rawValue.titleCased
        }
    }
}

extension FCPXML.Marker.MarkerKind {
    var name: String {
        switch self {
        case .standard: "Standard"
        case .chapter: "Chapter"
        case .toDo: "To Do"
        }
    }
}

extension FCPXML.Marker.Configuration {
    var name: String {
        switch self {
        case .standard: "Standard"
        case .chapter: "Chapter"
        case .toDo: "To Do"
        }
    }
}

extension FCPXML.ExtractedCaption {
    var isOutOfBounds: Bool {
        value(forContext: .effectiveOcclusion) == .fullyOccluded
    }
}

extension FCPXML.ExtractedMarker {
    var isOutOfBounds: Bool {
        value(forContext: .effectiveOcclusion) == .fullyOccluded
    }
}
