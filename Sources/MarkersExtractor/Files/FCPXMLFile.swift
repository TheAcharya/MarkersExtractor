//
//  FCPXMLFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import DAWFileKit

/// Final Cut Pro XML file/bundle abstract file reference and content reader.
public struct FCPXMLFile {
    /// Maintains an objective reference to the fcpxml file.
    private let source: FCPXMLFileSource
    
    /// Reads and caches the actual XML file from disk.
    private var xmlFileContents: File
    
    public init(at url: URL) throws {
        let path = try FCPXMLFilePath(inputURL: url)
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
}

extension FCPXMLFile: CustomStringConvertible {
    public var description: String {
        switch source {
        case let .fileOnDisk(path):
            return "\(path.xmlPath.path.quoted)"
        case .rawFileContents:
            return "FCP XML Data"
        }
    }
}

extension FCPXMLFile {
    public enum FCPXMLFileSource {
        case fileOnDisk(FCPXMLFilePath)
        case rawFileContents
    }
    
    public enum FCPXMLFilePath {
        case fcpxml(xmlURL: URL)
        case fcpxmld(bundleURL: URL)
        
        public init(inputURL: URL) throws {
            if inputURL.pathExtension.caseInsensitiveCompare("fcpxml") == .orderedSame {
                self = .fcpxml(xmlURL: inputURL)
            } else if inputURL.pathExtension.caseInsensitiveCompare("fcpxmld") == .orderedSame {
                self = .fcpxmld(bundleURL: inputURL)
            } else {
                throw MarkersExtractorError.validation(
                    .unsupportedFileFormat(atPath: inputURL.path)
                )
            }
        }
        
        /// Returns the path to the directory containing the base path.
        public var parentPath: URL {
            basePath.deletingLastPathComponent()
        }
        
        /// Returns the base path.
        /// For an `fcpxml` file, the file's path is returned.
        /// For an `dcpxmld` bundle, the bundle's path is returned.
        public var basePath: URL {
            switch self {
            case .fcpxml(let xmlURL):
                return xmlURL
            case .fcpxmld(let bundleURL):
                return bundleURL
            }
        }
        
        /// Resolves the location of the actual XML file.
        public var xmlPath: URL {
            switch self {
            case .fcpxml(let xmlURL):
                return xmlURL
            case .fcpxmld(let bundleURL):
                return bundleURL.appendingPathComponent("Info.fcpxml")
            }
        }
    }
}

extension FCPXMLFile {
    // TODO: refactor so that this is processed on init, not on each access to data()
    mutating func data() throws -> Data {
        try xmlFileContents.data()
    }
    
    /// Convenience to return the Final Cut Pro XML file/bundle URL.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var baseURL: URL? {
        switch source {
        case let .fileOnDisk(path):
            return path.xmlPath
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
        case .rawFileContents:
            return nil
        }
    }
    
    /// Returns a new `XMLDocument` instance representing the XML file's contents.
    mutating func xmlDocument() throws -> XMLDocument {
        try XMLDocument(data: data())
    }
    
    mutating func dawFile() throws -> FinalCutPro.FCPXML {
        try FinalCutPro.FCPXML(fileContent: data())
    }
    
    var defaultMediaSearchPath: URL? {
        parentDir
    }
}
