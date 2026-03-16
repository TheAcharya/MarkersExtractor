//
//  NotionExportProfile Icon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation

extension NotionExportProfile {
    public enum Icon: ExportIcon {
        case markerChapter
        case markerToDoComplete
        case markerToDoIncomplete
        case markerStandard
        case caption
    }
}

extension NotionExportProfile.Icon: Equatable { }

extension NotionExportProfile.Icon: Hashable { }

extension NotionExportProfile.Icon: CaseIterable { }

extension NotionExportProfile.Icon: Sendable { }

// MARK: - Init

extension NotionExportProfile.Icon {
    public init(_ configuration: FCPXML.Marker.Configuration) {
        switch configuration {
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
}

// MARK: - Properties

extension NotionExportProfile.Icon {
    public var resource: EmbeddedResource {
        switch self {
        case .markerChapter: .icon_notion_marker_chapter_png
        case .markerToDoComplete: .icon_notion_marker_toDo_complete_png
        case .markerToDoIncomplete: .icon_notion_marker_toDo_incomplete_png
        case .markerStandard: .icon_notion_marker_png
        case .caption: .icon_notion_caption_png
        }
    }
    
    public var fileName: String {
        resource.fileName
    }
    
    public var data: Data {
        resource.data ?? Data()
    }
}
