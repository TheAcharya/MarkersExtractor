//
//  ExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging
import OrderedCollections
import TimecodeKit

public protocol ExportProfile: AnyObject where Self: ProgressReporting {
    associatedtype Payload: ExportPayload
    associatedtype PreparedMarker: ExportMarker
    associatedtype Icon: ExportIcon
    
    /// Exports markers to disk.
    /// Writes metadata files, images, and any other resources necessary.
    func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        media: ExportMedia?,
        tcStringFormat: Timecode.StringFormat,
        outputURL: URL,
        payload: Payload,
        createDoneFile: Bool,
        doneFilename: String,
        logger: Logger?,
        parentProgress: ParentProgress?
    ) async throws
    
    /// Converts raw FCP markers to the native format needed for export.
    /// If media is not present, pass `nil` to `mediaInfo` to bypass thumbnail generation.
    func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker]
    
    /// Encode and write metadata manifest file to disk. (Such as csv file)
    func writeManifest(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws
    
    /// Provides the done file content.
    func doneFileContent(payload: Payload) throws -> Data
    
    func manifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String>
    
    /// Boolean describing whether the export format is capable of using media.
    /// (ie: able to generate thumbnail image files, etc.)
    static var isMediaCapable: Bool { get }
    
    var logger: Logger? { get set }
    
    init(logger: Logger?)
}

extension ExportProfile {
    /// Progress instance factory.
    static var defaultProgress: Progress {
        Progress(totalUnitCount: defaultProgressTotalUnitCount)
    }
    
    /// Arbitrary overall progress total for export profile.
    static var defaultProgressTotalUnitCount: Int64 { 100 }
}
