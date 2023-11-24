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
    /// Export profile used.
    public var profile: ExportProfileFormat
    
    /// Output folder path used for the export.
    public var exportFolder: URL
    
    /// CSV manifest file path, if applicable to the profile. `nil` if not applicable.
    public var csvManifestPath: URL?
    
    /// CSV manifest file path, if applicable to the profile. `nil` if not applicable.
    public var jsonManifestPath: URL?
    
    /// MIDI file path, if applicable to the profile. `nil` if not applicable.
    public var midiFilePath: URL?
    
    public init(
        profile: ExportProfileFormat,
        exportFolder: URL,
        csvManifestPath: URL? = nil,
        jsonManifestPath: URL? = nil,
        midiFilePath: URL? = nil
    ) {
        self.profile = profile
        self.exportFolder = exportFolder
        self.csvManifestPath = csvManifestPath
        self.jsonManifestPath = jsonManifestPath
        self.midiFilePath = midiFilePath
    }
}

extension ExportResult {
    public typealias ResultDictionary = [Key: Value]
    
    /// Keys used in the result file JSON dictionary.
    public enum Key: String, Equatable, Hashable, CaseIterable {
        case profile
        case exportFolder
        case csvManifestPath
        case jsonManifestPath
        case midiFilePath
    }
    
    /// Type-erased box to maintain type safety for the intermediate dictionary.
    public enum Value: Equatable, Hashable {
        case string(_ string: String)
        case url(_ url: URL)
        case profile(_ profile: ExportProfileFormat)
        
        public var stringValueForJSON: String {
            switch self {
            case let .string(string): return string
            case let .url(url): return url.path
            case let .profile(profile): return profile.rawValue
            }
        }
    }
}

extension ExportResult {
    /// Updates local properties from a dictionary's contents.
    mutating func update(with dict: [Key: Value]) {
        if let value = dict[.profile], case let .profile(exportProfile) = value {
            profile = exportProfile
        }
        if let value = dict[.exportFolder], case let .url(url) = value {
            exportFolder = url
        }
        if let value = dict[.csvManifestPath], case let .url(url) = value {
            csvManifestPath = url
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
        
        dict[.profile] = profile.rawValue
        dict[.exportFolder] = exportFolder.path
        dict[.csvManifestPath] = csvManifestPath?.path
        dict[.jsonManifestPath] = jsonManifestPath?.path
        dict[.midiFilePath] = midiFilePath?.path
        
        return dict.mapKeys(\.rawValue)
    }
    
    /// Returns the contents as a JSON-encoded data.
    func jsonData() throws -> Data {
        try dictToJSON(exportResultContentDict())
    }
}
