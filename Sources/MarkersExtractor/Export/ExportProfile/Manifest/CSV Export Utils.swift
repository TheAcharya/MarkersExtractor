//
//  CSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TextFile

extension ExportProfile {
    func csvWriteManifest(
        csvPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: true, noMedia: noMedia)

        let data: Data
        do throws(TextFileEncodeError) {
            data = try CSV(table: rows).data(encoding: .utf8, includeBOM: true)
        } catch {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode CSV file: \(error.localizedDescription)"
            ))
        }

        do {
            try data.write(to: csvPath)
        } catch {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not write CSV file to disk: \(error.localizedDescription)"
            ))
        }
    }
}
