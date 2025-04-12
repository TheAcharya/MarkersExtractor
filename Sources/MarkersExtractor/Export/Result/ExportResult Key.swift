//
//  ExportResult Key.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension ExportResult {
    /// Keys used in the result file JSON dictionary.
    public enum Key: String {
        /// Date of extraction operation (ISO8601 formatted).
        case date
        
        /// Export profile used.
        case profile
        
        /// Output folder path used for the export.
        case exportFolder
        
        /// CSV manifest file path, if applicable to the profile. `nil` if not applicable.
        case csvManifestPath
        
        /// TSV manifest file path, if applicable to the profile. `nil` if not applicable.
        case tsvManifestPath
        
        /// Plain Text manifest file path, if applicable to the profile. `nil` if not applicable.
        case txtManifestPath
        
        /// Markdown manifest file path, if applicable to the profile. `nil` if not applicable.
        case mdManifestPath
        
        /// JSON manifest file path, if applicable to the profile. `nil` if not applicable.
        case jsonManifestPath
        
        /// MIDI file path, if applicable to the profile. `nil` if not applicable.
        case midiFilePath
        
        /// Excel (XLSX) file path, if applicable to the profile. `nil` if not applicable.
        case xlsxManifestPath
        
        /// MarkersExtractor version used to perform extraction.
        case version
    }
}

extension ExportResult.Key: Equatable { }

extension ExportResult.Key: Hashable { }

extension ExportResult.Key: CaseIterable { }

extension ExportResult.Key: Sendable { }
