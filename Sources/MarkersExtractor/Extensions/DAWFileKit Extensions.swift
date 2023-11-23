//
//  DAWFileKit Extensions.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit

extension FinalCutPro.FCPXML.ElementType {
    var name: String {
        switch self {
        case let .story(storyElementType):
            return storyElementType.name
            
        case let .structure(structureElementType):
            return structureElementType.name
        }
    }
}

extension FinalCutPro.FCPXML.StoryElementType {
    var name: String {
        switch self {
        case let .anyAnnotation(annotationType):
            return annotationType.name
            
        case let .anyClip(clipType):
            return clipType.name
        
        case .sequence:
            return "Sequence"
            
        case .spine:
            return "Spine"
        }
    }
}


extension FinalCutPro.FCPXML.StructureElementType {
    var name: String {
        switch self {
        case .library:
            return "Library"
        case .event:
            return "Event"
        case .project:
            return "Project"
        }
    }
}

extension FinalCutPro.FCPXML.AnnotationType {
    var name: String {
        switch self {
        case .caption:
            return "Caption"
            
        case .keyword:
            return "Keyword"
            
        case .marker, .chapterMarker:
            return "Marker"
        }
    }
}


extension FinalCutPro.FCPXML.ClipType {
    var name: String {
        switch self {
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
        case .video: return "Video"
        }
    }
}
