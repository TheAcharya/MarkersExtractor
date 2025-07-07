//
//  XLSX Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TextFileKit
import XLKit
import CoreGraphics
import ImageIO

// MARK: - Type Aliases

typealias StringTable = [[String]]

extension ExportProfile {
    func xlsxWriteManifest(
        xlsxPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker],
        outputFolder: URL? = nil
    ) throws {
        print("Starting XLSX manifest generation...")
        print("XLSX path: \(xlsxPath.path)")
        print("No media: \(noMedia)")
        print("Output folder: \(outputFolder?.path ?? "nil")")
        print("Number of markers: \(preparedMarkers.count)")
        
        let rows = dictsToRows(preparedMarkers, includeHeader: true, noMedia: noMedia)
        print("Generated \(rows.count) rows (including header)")
        
        if let headerRow = rows.first {
            print("Header row: \(headerRow)")
        }
        
        // Create a new workbook
        let workbook = Workbook()
        
        // Add a worksheet with default name
        let sheet = workbook.addSheet(name: "Sheet1")
        
        // Set up formats
        var boldFormat = CellFormat()
        boldFormat.fontWeight = .bold
        boldFormat.fontSize = 12
        
        // Write header cells with bold formatting
        guard let headerRowValues = rows.first else { return }
        for (columnIndex, value) in headerRowValues.enumerated() {
            let coordinate = CellCoordinate(row: 1, column: columnIndex + 1).excelAddress
            sheet.setCell(coordinate, string: value, format: boldFormat)
        }
        
        // Write data rows
        let dataRows = rows.dropFirst()
        for (rowIndex, rowValues) in dataRows.enumerated() {
            for (columnIndex, value) in rowValues.enumerated() {
                let coordinate = CellCoordinate(row: rowIndex + 2, column: columnIndex + 1).excelAddress
                sheet.setCell(coordinate, string: value)
            }
        }
        
        // Add images if media is present and output folder is available
        if !noMedia, let outputFolder = outputFolder {
            print("Adding images to sheet...")
            try addImagesToSheet(sheet: sheet, preparedMarkers: preparedMarkers, outputFolder: outputFolder, workbook: workbook)
        } else {
            print("Skipping image embedding - noMedia: \(noMedia), outputFolder: \(outputFolder != nil)")
        }
        
        // Auto-adjust column widths based on content
        print("Auto-adjusting column widths...")
        autoAdjustColumnWidths(sheet: sheet, rows: rows)
        
        // Generate the XLSX file
        print("Generating XLSX file...")
        try XLSXEngine.generateXLSX(workbook: workbook, to: xlsxPath)
        print("XLSX file generated successfully at: \(xlsxPath.path)")
    }
    
    private func addImagesToSheet(
        sheet: Sheet,
        preparedMarkers: [PreparedMarker],
        outputFolder: URL,
        workbook: Workbook
    ) throws {
        let headerRow = dictsToRows(preparedMarkers, includeHeader: true, noMedia: false).first ?? []
        guard let imagesColumnIndex = headerRow.firstIndex(of: "Images") else { return }
        let excelColumnIndex = imagesColumnIndex + 1

        for (rowIndex, marker) in preparedMarkers.enumerated() {
            let imageFileName = marker.imageFileName
            guard !imageFileName.isEmpty else { continue }
            let imagePath = outputFolder.appendingPathComponent(imageFileName)
            guard FileManager.default.fileExists(atPath: imagePath.path) else { continue }
            let imageData = try Data(contentsOf: imagePath)
            let fileExtension = imagePath.pathExtension.lowercased()
            let imageFormat: ImageFormat
            switch fileExtension {
            case "png": imageFormat = .png
            case "jpg", "jpeg": imageFormat = .jpeg
            case "gif": imageFormat = .gif
            default: continue // skip unsupported
            }
            
            // Use XLKit's embedImageAutoSized with automatic scaling (default 0.5 scale)
            let excelRowIndex = rowIndex + 2 // 1-based, + header
            let coordinate = CellCoordinate(row: excelRowIndex, column: excelColumnIndex).excelAddress
            sheet.embedImageAutoSized(imageData, at: coordinate, of: workbook, format: imageFormat)
        }
    }
    
    private func autoAdjustColumnWidths(sheet: Sheet, rows: [[String]]) {
        guard !rows.isEmpty else { return }
        
        let headerRow = rows[0]
        let dataRows = rows.dropFirst()
        
        // Calculate maximum width for each column
        for (columnIndex, headerValue) in headerRow.enumerated() {
            var maxWidth = 0.0
            
            // Check header width
            let headerWidth = calculateTextWidth(headerValue, isBold: true)
            maxWidth = max(maxWidth, headerWidth)
            
            // Check data row widths
            for row in dataRows {
                if columnIndex < row.count {
                    let dataWidth = calculateTextWidth(row[columnIndex], isBold: false)
                    maxWidth = max(maxWidth, dataWidth)
                }
            }
            
            // Add some padding and set column width
            let adjustedWidth = maxWidth + 3.0 // Add 3 units of padding for better readability
            let clampedWidth = adjustedWidth.clamped(to: 8.0 ... 120.0) // Min 8, Max 120 for better range
            sheet.setColumnWidth(columnIndex + 1, width: clampedWidth)
        }
    }
    
    private func calculateTextWidth(_ text: String, isBold: Bool) -> Double {
        // Approximate character width calculation
        // This is a simplified approach - in a real implementation you might want to use
        // Core Text or other font metrics for more accurate calculations
        
        let baseCharWidth = isBold ? 1.2 : 1.0 // Bold text is slightly wider
        let fontSize = isBold ? 12.0 : 11.0 // Header vs data font size
        
        // Account for multi-line text (if text contains newlines)
        let lines = text.components(separatedBy: .newlines)
        let maxLineLength = lines.map { $0.count }.max() ?? 0
        
        // For multi-line text, use the longest line
        let adjustedCharCount = Double(maxLineLength)
        let finalWidth = adjustedCharCount * baseCharWidth * (fontSize / 10.0)
        
        return finalWidth
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
