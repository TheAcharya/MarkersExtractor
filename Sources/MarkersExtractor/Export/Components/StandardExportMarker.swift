//
//  StandardExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections

/// A marker with its contents prepared as flat String values in a standard format suitable for
/// various different export profiles.
public struct StandardExportMarker: ExportMarker {    
    public typealias Field = StandardExportField
    public typealias Icon = NotionExportProfile.Icon
        
    public let id: String
    public let name: String
    public let type: String
    public let checked: String
    public let status: String
    public let notes: String
    public let position: String
    public let clipName: String
    public let clipDuration: String
    public let audioRoles: String
    public let videoRoles: String
    public let eventName: String
    public let projectName: String
    public let libraryName: String
    public let icon: Icon
    public let imageFileName: String
        
    public init(
        _ marker: Marker,
        idMode: MarkerIDMode,
        imageFormat: MarkerImageFormat,
        isSingleFrame: Bool
    ) {
        id = marker.id(idMode)
        name = marker.name
        type = marker.type.name
        checked = String(marker.isChecked())
        status = NotionExportProfile.Status(marker.type).rawValue
        notes = marker.notes
        position = marker.positionTimecodeString()
        clipName = marker.parentInfo.clipName
        clipDuration = marker.parentInfo.clipDurationTimecodeString
        videoRoles = marker.roles.flattenedString()
        audioRoles = marker.roles.flattenedString()
        eventName = marker.parentInfo.eventName
        projectName = marker.parentInfo.projectName
        libraryName = marker.parentInfo.libraryName
        icon = Icon(marker.type)
        imageFileName = isSingleFrame
            ? "marker-placeholder.\(imageFormat)"
            : "\(marker.id(pathSafe: idMode)).\(imageFormat)"
    }
}
