//
//  NotionExportProfile Icon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension NotionExportProfile {
    public enum Icon: ExportIcon {
        case chapter
        case completed
        case todo
        case standard
        
        public init(_ type: MarkerType) {
            switch type {
            case .standard:
                self = .standard
            case let .todo(completed):
                self = completed ? .completed : .todo
            case .chapter:
                self = .chapter
            }
        }
        
        public var resource: EmbeddedResource {
            switch self {
            case .chapter: return .notion_marker_chapter_png
            case .completed: return .notion_marker_completed_png
            case .todo: return .notion_marker_to_do_png
            case .standard: return .notion_marker_png
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
