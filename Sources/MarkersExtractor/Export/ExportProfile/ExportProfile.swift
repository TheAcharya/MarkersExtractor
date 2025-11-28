//
//  ExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging
import OrderedCollections
import SwiftTimecodeCore

public protocol ExportProfile: Sendable {
    associatedtype Payload: ExportPayload
    associatedtype PreparedMarker: ExportMarker
    associatedtype Icon: ExportIcon
    
    static var profile: ExportProfileFormat { get }
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    var progress: Progress { get }
    
    /// Exports markers to disk.
    /// Writes metadata files, images, and any other resources necessary.
    func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        media: ExportMedia?,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        outputURL: URL,
        payload: Payload,
        resultFilePath: URL?,
        logger: Logger?,
        parentProgress: ParentProgress?
    ) async throws -> ExportResult
    
    /// Converts raw FCP markers to the native format needed for export.
    /// If media is not present, pass `nil` to `mediaInfo` to bypass thumbnail generation.
    func prepareMarkers(
        markers: [Marker],
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        payload: Payload,
        mediaInfo: ExportMarkerMediaInfo?
    ) -> [PreparedMarker]
    
    /// Encode and write all applicable metadata manifest file(s) to disk. (Such as csv file)
    func writeManifests(
        _ preparedMarkers: [PreparedMarker],
        payload: Payload,
        noMedia: Bool
    ) throws
    
    /// Provides the profile-specific result file content.
    func resultFileContent(payload: Payload) throws -> ExportResult.ResultDictionary
    
    /// Provides the manifest fields to use for table-based data structure (ie: for CSV, TSV, etc.).
    /// These values are also used for thumbnail image labels.
    func tableManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, String>
    
    /// Provides the manifest fields to use for nested-based data structure (ie: for JSON, XML,
    /// PLIST, etc.).
    /// Defaults to using ``tableManifestFields(for:noMedia:)`` if no implementation is provided.
    func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue>
    
    /// Boolean describing whether the export format is capable of using media.
    /// (ie: able to generate thumbnail image files, etc.)
    static var isMediaCapable: Bool { get }
    
    var logger: Logger? { get }
    
    init(logger: Logger?)
}

// MARK: - Static

extension ExportProfile {
    /// Progress instance factory.
    static var defaultProgress: Progress {
        Progress(totalUnitCount: defaultProgressTotalUnitCount)
    }
    
    /// Arbitrary overall progress total for export profile.
    static var defaultProgressTotalUnitCount: Int64 { 100 }
}

// MARK: - Default Implementation

extension ExportProfile {
    public func nestedManifestFields(
        for marker: PreparedMarker,
        noMedia: Bool
    ) -> OrderedDictionary<ExportField, ExportFieldValue> {
        tableManifestFields(for: marker, noMedia: noMedia)
            .mapValues { .string($0) }
    }
}
