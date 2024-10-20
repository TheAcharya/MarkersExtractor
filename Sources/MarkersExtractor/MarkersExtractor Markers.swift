//
//  MarkersExtractor Markers.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit
import TimecodeKitCore

// MARK: - Extract Markers

extension MarkersExtractor {
    static let defaultTimelineName = "Timeline"
    
    /// Extract markers from `fcpxml` and optionally sort them chronologically by timecode.
    ///
    /// Does not perform any ID uniquing.
    /// To subsequently unique the resulting `[Marker]`, call `uniquingMarkerIDs(in:)`
    ///
    /// - Throws: ``MarkersExtractorError``
    func extractMarkers(
        sort: Bool = true,
        parentProgress: ParentProgress? = nil
    ) async throws -> (
        markers: [Marker],
        context: FCPXMLMarkerExtractor.TimelineContext
    ) {
        let extractor: FCPXMLMarkerExtractor
        var markers: [Marker]
        
        do {
            extractor = try FCPXMLMarkerExtractor(
                fcpxml: &s.fcpxml,
                idNamingMode: s.idNamingMode,
                enableSubframes: s.enableSubframes, 
                markersSource: s.markersSource,
                excludeRoles: s.excludeRoles, 
                includeDisabled: s.includeDisabled,
                logger: logger
            )
        } catch {
            throw MarkersExtractorError.extraction(.fcpxmlParse(
                "Failed to parse \(s.fcpxml): \(error.localizedDescription)"
            ))
        }
        
        // attach local progress to parent
        parentProgress?.addChild(extractor.progress)
        
        guard let context = extractor.extractTimelineContext(defaultTimelineName: Self.defaultTimelineName)
        else {
            // method already logs any specific errors
            throw MarkersExtractorError.extraction(.fcpxmlParse("Error extracting timeline context."))
        }
        
        markers = await extractor.extractMarkers(context: context)
        
        if !isAllUniqueIDNonEmpty(in: markers) {
            throw MarkersExtractorError.extraction(.fcpxmlParse(
                "Empty marker ID encountered. Markers must have valid non-empty IDs."
            ))
        }
        
        let duplicates = findDuplicateIDs(in: markers)
        if !duplicates.isEmpty {
            // duplicate marker IDs isn't be an error condition, we should append filename uniquing
            // string to the ID instead.
            // throw MarkersExtractorError.runtimeError("Duplicate marker IDs found: \(duplicates)")
            duplicates.forEach {
                logger.info("Duplicate marker ID found which will be uniqued: \($0.quoted)")
            }
        }
        
        if sort {
            markers.sort()
        }
        
        return (markers: markers, context: context)
    }
}

// MARK: - Helpers

extension MarkersExtractor {
    /// Uniques marker IDs. (Works better if the array is sorted by timecode first.)
    func uniquingMarkerIDs(in markers: [Marker]) -> [Marker] {
        var markers = markers
        
        let dupeIndices = Dictionary(
            grouping: markers.indices,
            by: { markers[$0].id(s.idNamingMode, tcStringFormat: timecodeStringFormat) }
        )
        .filter { $1.count > 1 }
        
        for (_, indices) in dupeIndices {
            var counter = 1
            for index in indices {
                markers[index].idSuffix = "-\(counter)"
                counter += 1
            }
        }
        
        return markers
    }
    
    func findDuplicateIDs(in markers: [Marker]) -> [String] {
        Dictionary(
            grouping: markers,
            by: { $0.id(s.idNamingMode, tcStringFormat: timecodeStringFormat) }
        )
        .filter { $1.count > 1 }
        .compactMap { $0.1.first }
        .map { $0.id(s.idNamingMode, tcStringFormat: timecodeStringFormat) }
        .sorted()
    }
    
    func isAllUniqueIDNonEmpty(in markers: [Marker]) -> Bool {
        markers
            .map { $0.id(s.idNamingMode, tcStringFormat: timecodeStringFormat) }
            .allSatisfy { !$0.isEmpty }
    }
}
