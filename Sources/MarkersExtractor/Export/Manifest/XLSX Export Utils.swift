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
        
        var rowIndex = 0
        
        // write header cells
        guard let headerRow = rows.first else { return }
        ws.write(row: rowIndex, cells: headerRow, format: formatBold)
        rowIndex += 1
        
        // write data rows
        let dataRows = rows.dropFirst()
        for rowValues in dataRows {
            ws.write(row: rowIndex, cells: rowValues)
            rowIndex += 1
        }
    }
}

extension Worksheet {
    fileprivate func write(row rowIndex: Int, cells: [String], format: Format? = nil) {
        for (columnIndex, cellValue) in cells.enumerated() {
            write(
                .string(cellValue),
                [rowIndex, columnIndex],
                format: format
            )
        }
    }
}
