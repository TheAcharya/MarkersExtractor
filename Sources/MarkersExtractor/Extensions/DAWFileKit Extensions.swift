//
//  DAWFileKit Extensions.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

extension FinalCutPro.FCPXML.ElementType {
    var name: String {
        switch self {
        // annotation
            
        case .caption: return "Caption"
        case .keyword: return "Keyword"
        case .marker, .chapterMarker: return "Marker"
            
        // story
            
        case .sequence: return "Sequence"
        case .spine: return "Spine"
            
        // clips
            
        case .assetClip: return "Asset"
        case .audio: return "Audio"
        case .audition: return "Audition"
        case .clip: return "Clip"
        case .gap: return "Gap"
        case .liveDrawing: return "Live Drawing"
        case .mcClip: return "Multicam"
        case .refClip: return "Compound"
        case .syncClip: return "Sync"
        case .title: return "Title"
        case .transition: return "Transition"
        case .video: return "Video"
            
        // structure
            
        case .library: return "Library"
        case .event: return "Event"
        case .project: return "Project"
            
        default:
            return rawValue.titleCased
        }
    }
}

extension FinalCutPro.FCPXML.Marker.MarkerKind {
    var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .toDo: return "To Do"
        }
    }
}

extension FinalCutPro.FCPXML.Marker.Configuration {
    var name: String {
        switch self {
        case .standard: return "Standard"
        case .chapter: return "Chapter"
        case .toDo: return "To Do"
        }
    }
}

extension FinalCutPro.FCPXML.ExtractedCaption {
    var isOutOfBounds: Bool {
        value(forContext: .effectiveOcclusion) == .fullyOccluded
    }
}

extension FinalCutPro.FCPXML.ExtractedMarker {
    var isOutOfBounds: Bool {
        value(forContext: .effectiveOcclusion) == .fullyOccluded
    }
}
