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
    /// Generates an XLSX file with marker data and optional embedded images.
    /// 
    /// ## XLKit API Implementation Notes:
    /// 
    /// ### Main Actor Isolation
    /// XLKit 1.0+ requires all operations to be performed on the main actor due to concurrency safety.
    /// This function is marked as `@MainActor` to ensure all XLKit API calls run on the main actor.
    /// 
    /// ### Key XLKit Components Used:
    /// - `Workbook`: The main container for the Excel file
    /// - `Sheet`: Individual worksheet within the workbook
    /// - `CellCoordinate`: Represents cell positions (1-based indexing)
    /// - `CellFormat`: Defines cell styling (font, size, weight, etc.)
    /// - `workbook.save(to:)`: Handles file generation and writing (async)
    /// 
    /// ### Cell Addressing
    /// XLKit uses 1-based indexing for both rows and columns. Cell coordinates are converted
    /// to Excel-style addresses (A1, B2, etc.) using the `.excelAddress` property.
    /// 
    /// ### Image Embedding
    /// Images are embedded using `sheet.embedImageAutoSized()` which automatically
    /// resizes images to fit within cell boundaries while maintaining aspect ratio.
    /// The method is async and must be awaited.
    /// 
    /// ### Column Width Auto-Adjustment
    /// Column widths are calculated based on content length and font properties,
    /// then clamped to reasonable bounds (8-120 units) for better readability.
    /// 
    /// ### Security Considerations
    /// XLKit includes file path restrictions and security validation by default.
    /// The `SecurityManager` handles file validation and suspicious file detection.
    @MainActor
    func xlsxWriteManifest(
        xlsxPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker],
        outputFolder: URL? = nil
    ) async throws {
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
        
        // Prepare image data if needed
        var imageDataArray: [(rowIndex: Int, imageData: Data, imageFormat: ImageFormat)] = []
        if !noMedia, let outputFolder = outputFolder {
            let headerRow = dictsToRows(preparedMarkers, includeHeader: true, noMedia: false).first ?? []
            guard headerRow.contains("Image") else { return }
            
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
                imageDataArray.append((rowIndex: rowIndex, imageData: imageData, imageFormat: imageFormat))
            }
        }
        
        // Prepare header row for image column index calculation
        let headerRowForImage = dictsToRows(preparedMarkers, includeHeader: true, noMedia: false).first ?? []
        let imageColumnIndex = headerRowForImage.firstIndex(of: "Image") ?? -1
        let excelColumnIndex = imageColumnIndex + 1
        
        // MARK: - XLKit Operations (Main Actor Required)
        // All XLKit operations are performed on the main actor due to concurrency safety
        // requirements in XLKit 1.0+. This includes workbook creation, sheet manipulation,
        // cell formatting, and file generation.
        
        // Create a new workbook - this is the root container for the Excel file
        let workbook = Workbook()
        
        // Add a worksheet with default name - sheets are the individual tabs in Excel
        let sheet = workbook.addSheet(name: "Sheet1")
        
        // Set up cell formatting for header row
        // CellFormat allows customization of font properties, borders, colors, etc.
        var boldFormat = CellFormat()
        boldFormat.fontWeight = .bold
        boldFormat.fontSize = 12
        boldFormat.backgroundColor = "#333333" // Light black (dark gray) background
        boldFormat.fontColor = "#FFFFFF" // White text
        boldFormat.horizontalAlignment = .center // Center text horizontally
        boldFormat.verticalAlignment = .center // Center text vertically
        
        // Write header cells with bold formatting
        // CellCoordinate uses 1-based indexing and converts to Excel-style addresses (A1, B1, etc.)
        guard let headerRowValues = rows.first else { return }
        for (columnIndex, value) in headerRowValues.enumerated() {
            let coordinate = CellCoordinate(row: 1, column: columnIndex + 1).excelAddress
            sheet.setCell(coordinate, string: value, format: boldFormat)
        }
        
        // Set up cell formatting for data rows (centered text)
        var dataFormat = CellFormat()
        dataFormat.horizontalAlignment = .center // Center text horizontally
        dataFormat.verticalAlignment = .center // Center text vertically
        
        // Write data rows with centered formatting
        let dataRows = rows.dropFirst()
        for (rowIndex, rowValues) in dataRows.enumerated() {
            for (columnIndex, value) in rowValues.enumerated() {
                let coordinate = CellCoordinate(row: rowIndex + 2, column: columnIndex + 1).excelAddress
                sheet.setCell(coordinate, string: value, format: dataFormat)
            }
        }
        
        // Auto-adjust column widths based on content FIRST
        // This improves readability by ensuring columns are wide enough for their content
        print("Auto-adjusting column widths...")
        Self.autoAdjustColumnWidths(sheet: sheet, rows: rows)
        
        // Add images if media is present AFTER column width adjustment
        // embedImageAutoSized will override the image column with perfect sizing
        if !imageDataArray.isEmpty && imageColumnIndex >= 0 {
            print("Adding images to sheet...")
            
            for (rowIndex, imageData, imageFormat) in imageDataArray {
                let excelRowIndex = rowIndex + 2 // 1-based, + header
                let coordinate = CellCoordinate(row: excelRowIndex, column: excelColumnIndex).excelAddress
                print("Embedding image at \(coordinate) with format \(imageFormat)")
                _ = try await sheet.embedImageAutoSized(
                    imageData, 
                    at: coordinate, 
                    of: workbook, 
                    format: imageFormat,
                    scale: 1.0  // Increase scale factor to 100% (larger visible images)
                )
                print("✓ Successfully embedded image at \(coordinate)")
            }
        } else {
            print("Skipping image embedding - no images found")
        }
        
        // Generate the XLSX file using the async save API
        print("Generating XLSX file...")
        try await workbook.save(to: xlsxPath)
        
        print("XLSX file generated successfully at: \(xlsxPath.path)")
    }
    

    
    /// Automatically adjusts column widths based on content length and font properties.
    /// 
    /// ## XLKit Column Width Implementation:
    /// 
    /// ### Width Units
    /// XLKit uses a custom width unit system that approximates character widths.
    /// The calculation considers font weight (bold vs normal) and font size.
    /// 
    /// ### Width Calculation Process:
    /// 1. Calculate text width for header (bold, larger font)
    /// 2. Calculate text width for all data cells in the column
    /// 3. Find the maximum width across all cells
    /// 4. Add padding (3 units) for better readability
    /// 5. Clamp to reasonable bounds (8-120 units)
    /// 
    /// ### Multi-line Text Handling
    /// For text containing newlines, the longest line is used for width calculation.
    /// This prevents columns from becoming too narrow for multi-line content.
    private static func autoAdjustColumnWidths(sheet: Sheet, rows: [[String]]) {
        guard !rows.isEmpty else { return }
        
        let headerRow = rows[0]
        let dataRows = rows.dropFirst()
        
        // Calculate maximum width for each column
        for (columnIndex, headerValue) in headerRow.enumerated() {
            var maxWidth = 0.0
            
            // Check header width (bold, larger font)
            let headerWidth = calculateTextWidth(headerValue, isBold: true)
            maxWidth = max(maxWidth, headerWidth)
            
            // Check data row widths (normal font)
            for row in dataRows {
                if columnIndex < row.count {
                    let dataWidth = calculateTextWidth(row[columnIndex], isBold: false)
                    maxWidth = max(maxWidth, dataWidth)
                }
            }
            
            // Add padding and set column width
            let adjustedWidth = maxWidth + 3.0 // Add 3 units of padding for better readability
            let clampedWidth = adjustedWidth.clamped(to: 8.0 ... 120.0) // Min 8, Max 120 for better range
            sheet.setColumnWidth(columnIndex + 1, width: clampedWidth)
        }
    }
    
    /// Calculates approximate text width based on character count, font weight, and font size.
    /// 
    /// ## Text Width Calculation Notes:
    /// 
    /// ### Font Properties Impact:
    /// - Bold text is approximately 20% wider than normal text
    /// - Header font size (12pt) vs data font size (11pt) affects width
    /// - Base character width is normalized to 1.0 for normal text
    /// 
    /// ### Multi-line Text Handling:
    /// - Text is split by newlines
    /// - The longest line determines the width
    /// - This prevents columns from being too narrow for multi-line content
    /// 
    /// ### Limitations:
    /// This is a simplified approximation. For more accurate calculations,
    /// consider using Core Text or other font metrics APIs.
    private static func calculateTextWidth(_ text: String, isBold: Bool) -> Double {
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
