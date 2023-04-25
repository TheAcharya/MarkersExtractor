//
//  ExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging
import OrderedCollections

public protocol ExportProfile {
    associatedtype Payload: ExportPayload
    associatedtype PreparedMarker: ExportMarker
    associatedtype Icon: ExportIcon
    
    /// Exports markers to disk.
    /// Writes metadata files, images, and any other resources necessary.
    static func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        media: ExportMedia?,
        outputURL: URL,
        payload: Payload,
        createDoneFile: Bool,
        doneFilename: String,
        logger: Logger?
    ) throws
    
    /// Converts raw FCP markers to the native format needed for export.
    /// If media is not present, pass `nil` to `mediaInfo` to bypass thumbnail generation.
    static func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker]
    
    /// Encode and write metadata manifest file to disk. (Such as csv file)
    static func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws
    
    static func doneFileContent(payload: Payload) throws -> Data
    
    static func manifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String>
}
