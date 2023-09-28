//
//  StandardExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TimecodeKit

/// A marker with its contents prepared as flat String values in a standard format suitable for
/// various different export profiles.
public struct StandardExportMarker: ExportMarker {
    public typealias Icon = NotionExportProfile.Icon
    
    public let id: String
    public let name: String
    public let type: String
    public let checked: String
    public let status: String
    public let notes: String
    public let position: String
    public let clipName: String
    public let clipFilename: String
    public let clipDuration: String
    public let audioRole: String
    public let videoRole: String
    public let eventName: String
    public let projectName: String
    public let libraryName: String
    public let icon: Icon
    
    public let imageFileName: String
    // public let mediaInfo: ExportMarkerMediaInfo?
    
    public init(
        _ marker: Marker,
        idMode: MarkerIDMode,
        mediaInfo: ExportMarkerMediaInfo?,
        tcStringFormat: Timecode.StringFormat
    ) {
        id = marker.id(idMode, tcStringFormat: tcStringFormat)
        name = marker.name
        type = marker.type.name
        checked = String(marker.isChecked())
        status = NotionExportProfile.Status(marker.type).rawValue
        notes = marker.notes
        position = marker.positionTimecodeString(format: tcStringFormat)
        clipName = marker.parentInfo.clipName
        clipFilename = marker.parentInfo.clipFilename
        clipDuration = marker.parentInfo.clipDurationTimecodeString(format: tcStringFormat)
        videoRole = marker.roles.videoFormatted()
        audioRole = marker.roles.audioFormatted()
        eventName = marker.parentInfo.eventName
        projectName = marker.parentInfo.projectName
        libraryName = marker.parentInfo.libraryName
        icon = Icon(marker.type)
        
        // self.mediaInfo = mediaInfo
        imageFileName = mediaInfo?
            .imageFileName(for: marker, idMode: idMode, tcStringFormat: tcStringFormat)
            ?? ""
    }
}
