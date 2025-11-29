//
//  FCPXMLFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation

/// Final Cut Pro XML file/bundle abstract file reference and content reader.
public struct FCPXMLFile {
    /// Maintains an objective reference to the fcpxml file.
    private let source: Source
    
    /// Reads and caches the actual XML file from disk.
    private var xmlFileContents: File
    
    public init(at url: URL) throws {
        let path = try FilePath(inputURL: url)
        source = .fileOnDisk(path)
        xmlFileContents = File(path.xmlPath)
    }
    
    public init(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try self.init(at: url)
    }
    
    public init(fileContents: Data) {
        source = .rawFileContents
        xmlFileContents = File(fileContents: .data(fileContents))
    }
    
    public init(fileContents: String) {
        source = .rawFileContents
        xmlFileContents = File(fileContents: .string(fileContents))
    }
    
    public init(fileContents: XMLDocument) {
        source = .xmlDocument(fileContents)
        xmlFileContents = File(fileContents: .data(fileContents.xmlData))
    }
}

extension FCPXMLFile: Equatable { }

extension FCPXMLFile: Hashable { }

extension FCPXMLFile: Identifiable {
    public var id: Self { self }
}

extension FCPXMLFile: CustomStringConvertible {
    public var description: String {
        switch source {
        case let .fileOnDisk(path):
            return "\(path.xmlPath.path.quoted)"
        case .xmlDocument(_):
            return "FCP XML Document"
        case .rawFileContents:
            return "FCP XML Data"
        }
    }
}

extension FCPXMLFile: Sendable { }

// MARK: - Properties

extension FCPXMLFile {
    /// Return file contents. Method is mutating because it maintains an internal cache.
    mutating func data() throws -> Data {
        try xmlFileContents.data()
    }
    
    /// Convenience to return the Final Cut Pro XML file/bundle URL.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var baseURL: URL? {
        switch source {
        case let .fileOnDisk(path):
            return path.xmlPath
        case .xmlDocument(_):
            return nil
        case .rawFileContents:
            return nil
        }
    }
    
    /// Returns the directory that contains the Final Cut Pro XML file/bundle.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var parentDir: URL? {
        switch source {
        case let .fileOnDisk(path):
            return path.parentPath
        case .xmlDocument(_):
            return nil
        case .rawFileContents:
            return nil
        }
    }
    
    /// Returns a new `XMLDocument` instance representing the XML file's contents.
    mutating func xmlDocument() throws -> XMLDocument {
        switch source {
        case let .xmlDocument(xmlDoc):
            return xmlDoc
        default:
            return try XMLDocument(data: data())
        }
    }
    
    mutating func dawFile() throws -> FinalCutPro.FCPXML {
        switch source {
        case let .xmlDocument(xmlDoc):
            return FinalCutPro.FCPXML(fileContent: xmlDoc)
        default:
            return try FinalCutPro.FCPXML(fileContent: data())
        }
    }
    
    var defaultMediaSearchPath: URL? {
        parentDir
    }
}
