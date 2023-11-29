//
//  NotionExportProfile Icon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

extension NotionExportProfile {
    public enum Icon: ExportIcon {
        case markerChapter
        case markerToDoComplete
        case markerToDoIncomplete
        case markerStandard
        case caption
        
        public init(_ type: FinalCutPro.FCPXML.Marker.MarkerMetaData) {
            switch type {
            case .standard:
                self = .markerStandard
            case let .toDo(completed):
                self = completed ? .markerToDoComplete : .markerToDoIncomplete
            case .chapter:
                self = .markerChapter
            }
        }
        
        public init(_ type: InterpretedMarkerType) {
            switch type {
            case let .marker(markerMetaData):
                self.init(markerMetaData)
            case .caption:
                self = .caption
            }
        }
        
        public var resource: EmbeddedResource {
            switch self {
            case .markerChapter: return .icon_notion_marker_chapter_png
            case .markerToDoComplete: return .icon_notion_marker_toDo_complete_png
            case .markerToDoIncomplete: return .icon_notion_marker_toDo_incomplete_png
            case .markerStandard: return .icon_notion_marker_png
            case .caption: return .icon_notion_caption_png
            }
        }
        
        public var fileName: String {
            resource.fileName
        }
        
        public var data: Data {
            resource.data ?? Data()
        }
    }
}
