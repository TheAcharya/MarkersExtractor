//
//  StandardExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TimecodeKitCore
import SwiftExtensions

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
    public let reel: String
    public let scene: String
    public let take: String
    public let position: String
    public let clipType: String
    public let clipName: String
    public let clipIn: String
    public let clipOut: String
    public let clipDuration: String
    public let clipKeywordsFlat: String
    public let clipKeywordsArray: [String]
    public let audioRoleFlat: String
    public let audioRoleArray: [String]
    public let videoRole: String
    public let eventName: String
    public let projectName: String
    public let libraryName: String
    public let icon: Icon
    
    public let imageFileName: String
    public let imageTimecode: Timecode
    
    public let xmlPath: String
    
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
        
        type = marker.type.name
        
        checked = String(marker.isChecked())
        
        status = NotionExportProfile.Status(marker.type).rawValue
        
        notes = marker.notes
        
        reel = marker.metadata.reel
        
        scene = marker.metadata.scene
        
        take = marker.metadata.take
        
        position = marker.positionTimeString(format: timeFormat, offsetToTimelineStart: offsetToTimelineStart)
        
        clipType = marker.parentInfo.clipType
        
        clipName = marker.parentInfo.clipName
        
        clipIn = marker.parentInfo.clipInTimeString(format: timeFormat)
        
        clipOut = marker.parentInfo.clipOutTimeString(format: timeFormat)
        
        clipDuration = marker.parentInfo.clipDurationTimeString(format: timeFormat)
        
        let (clipKeywordsFlat, clipKeywordsArray) = marker.parentInfo.clipKeywordsFormatted()
        self.clipKeywordsFlat = clipKeywordsFlat
        self.clipKeywordsArray = clipKeywordsArray
        
        videoRole = marker.roles.videoFormatted()
        
        let (audioRoleFlat, audioRoleArray) = marker.roles.audioFormatted(multipleRoleSeparator: ",")
        self.audioRoleFlat = audioRoleFlat
        self.audioRoleArray = audioRoleArray
        
        eventName = marker.parentInfo.eventName ?? ""
        
        projectName = marker.parentInfo.projectName ?? ""
        
        libraryName = marker.parentInfo.libraryName ?? ""
        
        icon = Icon(marker.type)
        
        imageFileName = mediaInfo?
            .imageFileName(for: marker, idMode: idMode, tcStringFormat: tcStringFormat)
            ?? ""
        
        imageTimecode = marker.imageTimecode(
            useChapterMarkerPosterOffset: useChapterMarkerPosterOffset, 
            offsetToTimelineStart: offsetToTimelineStart
        )
        
        xmlPath = marker.xmlPath
    }
}
