//
//  XLSX Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TextFileKit
import xlsxwriter

extension ExportProfile {
    func xlsxWriteManifest(
        xlsxPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let rows = dictsToRows(preparedMarkers, includeHeader: true, noMedia: noMedia)
        
        // Create a new workbook at specified path on disk.
        let wb = Workbook(name: xlsxPath.path)
        
        // ⚠️ must call close() to finish writing the file
        // ⚠️ but don't call close() more than once or it will crash!
        defer { wb.close() }
        
        // Add a worksheet with default name.
        let ws = wb.addWorksheet()
        
        // Set up formats.
        let formatBold = wb.addFormat()
        formatBold.bold()
        
        // cell coordinates: [Row, Column]
        
        // Write some simple text.
        ws.write(.string("Hello"), [0, 0], format: formatBold)
        
        // Text with formatting.
        ws.write(.string("World"), [1, 0])
    }
}
