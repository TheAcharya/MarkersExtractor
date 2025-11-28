//
//  MarkdownExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import SwiftTimecodeCore
import SwiftExtensions

/// A marker with its contents prepared for the Markdown export profile.
public struct MarkdownExportMarker: ExportMarker {
    public typealias Icon = EmptyExportIcon
    
    public let id: String
    public let name: String
    public let type: String?
    public let position: String
    public let notes: String
    public let icon: Icon
    
    public let imageFileName: String
    public let imageTimecode: Timecode
    
    public init(
        marker: Marker,
        idMode: MarkerIDMode,
        mediaInfo: ExportMarkerMediaInfo?,
        tcStringFormat: Timecode.StringFormat,
        timeFormat: ExportMarkerTimeFormat,
        offsetToTimelineStart: Bool = false,
        useChapterMarkerPosterOffset: Bool
    ) {
        id = marker.id(idMode, tcStringFormat: tcStringFormat)
        
        name = marker.name
        
        type = Self.typeString(for: marker.type)
        
        position = marker.positionTimeString(format: timeFormat, offsetToTimelineStart: offsetToTimelineStart)
        
        notes = marker.notes
        
        icon = EmptyExportIcon(.standard)
        
        imageFileName = mediaInfo?
            .imageFileName(for: marker, idMode: idMode, tcStringFormat: tcStringFormat)
            ?? ""
        
        imageTimecode = marker.imageTimecode(
            useChapterMarkerPosterOffset: useChapterMarkerPosterOffset, 
            offsetToTimelineStart: offsetToTimelineStart
        )
    }
}

extension MarkdownExportMarker {
    static func typeString(for interpretedType: InterpretedMarkerType) -> String? {
        switch interpretedType {
        case let .marker(markerType):
            switch markerType {
            case .standard: nil
            case .chapter(posterOffset: _): nil // "(Chapter)"
            case let .toDo(completed: completed): completed ? "(Done)" : "(Not Done)"
            }
        case .caption: nil // "(Caption)"
        }
    }
}
