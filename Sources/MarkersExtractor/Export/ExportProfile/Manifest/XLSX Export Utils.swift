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
        guard let headerRowValues = rows.first else { return }
        ws.write(row: headerRowValues.map { .string($0) }, [rowIndex, 0], format: formatBold)
        rowIndex += 1
        
        // write data rows
        let dataRows = rows.dropFirst()
        for rowValues in dataRows {
            ws.write(row: rowValues.map { .string($0) }, [rowIndex, 0])
            rowIndex += 1
        }
        
        // resize columns to fit contents
        // [Column Index: Character count]
        let columnMaxCharCounts = rows.columnMaxCharCounts
        for (columnIndex, charCount) in columnMaxCharCounts {
            let width = Double(charCount).clamped(to: 5 ... 100)
            ws.column([columnIndex, columnIndex], width: width)
        }
    }
}

// MARK: - Utils

extension StringTable {
    fileprivate var columnMaxCharCounts: [(columnIndex: Int, charCount: Int)] {
        columnCharCounts
            .map { ($0.key, $0.value.upperBound) }
            .sorted { lhs, rhs in lhs.columnIndex < rhs.columnIndex }
    }
}
