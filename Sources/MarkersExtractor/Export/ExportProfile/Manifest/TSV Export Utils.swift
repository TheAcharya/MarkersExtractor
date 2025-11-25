//
//  TSV Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TextFileTools

extension ExportProfile {
    func tsvWriteManifest(
        tsvPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: true, noMedia: noMedia)
        
        guard let tsvData = TextFile.TSV(table: rows).rawText.data(using: .utf8)
        else {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Could not encode TSV file."
            ))
        }
        
        try tsvData.write(to: tsvPath)
    }
}
