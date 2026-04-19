//
//  TSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TextFile

extension ExportProfile {
    func tsvWriteManifest(
        tsvPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: true, noMedia: noMedia)

        let data: Data
        do throws(TextFileEncodeError) {
            data = try TSV(table: rows).data(encoding: .utf8, includeBOM: true)
        } catch {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode TSV file: \(error.localizedDescription)"
            ))
        }

        do {
            try data.write(to: tsvPath)
        } catch {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not write TSV file to disk: \(error.localizedDescription)"
            ))
        }
    }
}
