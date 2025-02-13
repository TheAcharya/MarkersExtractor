//
//  ExportResult.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Standardized export results.
/// Returned by MarkersExtractor regardless the export profile used.
/// Properties that are not applicable to the export profile will be `nil`.
public struct ExportResult {
    /// Date the extraction was performed (ISO8601 formatted).
    public var date: Date
    
    /// Export profile used.
    public var profile: ExportProfileFormat
    
    /// Output folder path used for the export.
    public var exportFolder: URL
    
    /// CSV manifest file path, if applicable to the profile. `nil` if not applicable.
    public var csvManifestPath: URL?
    
    /// TSV manifest file path, if applicable to the profile. `nil` if not applicable.
    public var tsvManifestPath: URL?
    
    /// Plain Text manifest file path, if applicable to the profile. `nil` if not applicable.
    public var txtManifestPath: URL?
    
    /// JSON manifest file path, if applicable to the profile. `nil` if not applicable.
    public var jsonManifestPath: URL?
    
    /// MIDI file path, if applicable to the profile. `nil` if not applicable.
    public var midiFilePath: URL?
    
    /// Excel (XLSX) file path, if applicable to the profile. `nil` if not applicable.
    public var xlsxManifestPath: URL?
    
    /// MarkersExtractor version used to perform extraction.
    public var version: String
    
    public init(
        date: Date,
        profile: ExportProfileFormat,
        exportFolder: URL,
        csvManifestPath: URL? = nil,
        tsvManifestPath: URL? = nil,
        txtManifestPath: URL? = nil,
        jsonManifestPath: URL? = nil,
        midiFilePath: URL? = nil,
        xlsxManifestPath: URL? = nil
        // omit version from init parameters since we auto-set it
    ) {
        self.date = date
        self.profile = profile
        self.exportFolder = exportFolder
        self.csvManifestPath = csvManifestPath
        self.tsvManifestPath = tsvManifestPath
        self.txtManifestPath = txtManifestPath
        self.jsonManifestPath = jsonManifestPath
        self.midiFilePath = midiFilePath
        self.xlsxManifestPath = xlsxManifestPath
        version = packageVersion
    }
}

extension ExportResult: Equatable { }

extension ExportResult: Hashable { }

extension ExportResult: Sendable { }

// MARK: - Update

extension ExportResult {
    /// Updates local properties from a dictionary's contents.
    mutating func update(with dict: [Key: Value]) {
        if let value = dict[.date], case let .date(date) = value {
            self.date = date
        }
        if let value = dict[.profile], case let .profile(exportProfile) = value {
            profile = exportProfile
        }
        if let value = dict[.exportFolder], case let .url(url) = value {
            exportFolder = url
        }
        if let value = dict[.csvManifestPath], case let .url(url) = value {
            csvManifestPath = url
        }
        if let value = dict[.tsvManifestPath], case let .url(url) = value {
            tsvManifestPath = url
        }
        if let value = dict[.txtManifestPath], case let .url(url) = value {
            txtManifestPath = url
        }
        if let value = dict[.jsonManifestPath], case let .url(url) = value {
            jsonManifestPath = url
        }
        if let value = dict[.midiFilePath], case let .url(url) = value {
            midiFilePath = url
        }
        if let value = dict[.xlsxManifestPath], case let .url(url) = value {
            xlsxManifestPath = url
        }
        if let value = dict[.version], case let .string(ver) = value {
            version = ver
        }
    }
}

// MARK: - Conversion

extension ExportResult {
    /// Returns the contents serialized to a dictionary.
    func exportResultContentDict() -> [String: String] {
        var dict: [Key: String] = [:]
        
        dict[.date] = Value.date(date).stringValueForJSON
        dict[.profile] = profile.rawValue
        dict[.exportFolder] = exportFolder.path
        dict[.csvManifestPath] = csvManifestPath?.path
        dict[.tsvManifestPath] = tsvManifestPath?.path
        dict[.txtManifestPath] = txtManifestPath?.path
        dict[.jsonManifestPath] = jsonManifestPath?.path
        dict[.midiFilePath] = midiFilePath?.path
        dict[.xlsxManifestPath] = xlsxManifestPath?.path
        dict[.version] = version
        
        return dict.mapKeys(\.rawValue)
    }
    
    /// Returns the contents as a JSON-encoded data.
    func jsonData() throws -> Data {
        try dictToJSON(exportResultContentDict())
    }
}
