//
//  ExportResult.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Standardized export results.
/// Returned by MarkersExtractor regardless the export profile used.
/// Properties that are not applicable to the export profile will be `nil`.
public struct ExportResult: Equatable, Hashable {
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
    
    /// JSON manifest file path, if applicable to the profile. `nil` if not applicable.
    public var jsonManifestPath: URL?
    
    /// MIDI file path, if applicable to the profile. `nil` if not applicable.
    public var midiFilePath: URL?
    
    /// MarkersExtractor version used to perform extraction.
    public var version: String
    
    public init(
        date: Date,
        profile: ExportProfileFormat,
        exportFolder: URL,
        csvManifestPath: URL? = nil,
        tsvManifestPath: URL? = nil,
        jsonManifestPath: URL? = nil,
        midiFilePath: URL? = nil
    ) {
        self.date = date
        self.profile = profile
        self.exportFolder = exportFolder
        self.csvManifestPath = csvManifestPath
        self.tsvManifestPath = tsvManifestPath
        self.jsonManifestPath = jsonManifestPath
        self.midiFilePath = midiFilePath
        version = packageVersion
    }
}

extension ExportResult {
    public typealias ResultDictionary = [Key: Value]
    
    /// Keys used in the result file JSON dictionary.
    public enum Key: String, CaseIterable, Equatable, Hashable {
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
        
        /// JSON manifest file path, if applicable to the profile. `nil` if not applicable.
        case jsonManifestPath
        
        /// MIDI file path, if applicable to the profile. `nil` if not applicable.
        case midiFilePath
        
        /// MarkersExtractor version used to perform extraction.
        case version
    }
    
    /// Type-erased box to maintain type safety for the intermediate dictionary.
    public enum Value: Equatable, Hashable {
        case date(_ date: Date)
        case string(_ string: String)
        case url(_ url: URL)
        case profile(_ profile: ExportProfileFormat)
        
        public var stringValueForJSON: String {
            switch self {
            case let .date(date):
                return date.formatted(.iso8601)
            case let .string(string):
                return string
            case let .url(url): 
                return url.path
            case let .profile(profile):
                return profile.rawValue
            }
        }
    }
}

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
        if let value = dict[.jsonManifestPath], case let .url(url) = value {
            jsonManifestPath = url
        }
        if let value = dict[.midiFilePath], case let .url(url) = value {
            midiFilePath = url
        }
    }
    
    /// Returns the contents serialized to a dictionary.
    func exportResultContentDict() -> [String: String] {
        var dict: [Key: String] = [:]
        
        dict[.date] = Value.date(date).stringValueForJSON
        dict[.profile] = profile.rawValue
        dict[.exportFolder] = exportFolder.path
        dict[.csvManifestPath] = csvManifestPath?.path
        dict[.tsvManifestPath] = tsvManifestPath?.path
        dict[.jsonManifestPath] = jsonManifestPath?.path
        dict[.midiFilePath] = midiFilePath?.path
        dict[.version] = version
        
        return dict.mapKeys(\.rawValue)
    }
    
    /// Returns the contents as a JSON-encoded data.
    func jsonData() throws -> Data {
        try dictToJSON(exportResultContentDict())
    }
}
