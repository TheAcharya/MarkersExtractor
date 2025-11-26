//
//  FCPXMLFile FilePath.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation

extension FCPXMLFile {
    public enum FilePath {
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
    }
}

extension FCPXMLFile.FilePath: Equatable { }

extension FCPXMLFile.FilePath: Hashable { }

extension FCPXMLFile.FilePath: Identifiable {
    public var id: URL { basePath }
}

extension FCPXMLFile.FilePath: Sendable { }

// MARK: - Properties

extension FCPXMLFile.FilePath {
    /// Returns the path to the directory containing the base path.
    public var parentPath: URL {
        basePath.deletingLastPathComponent()
    }
    
    /// Returns the base path.
    /// For an `fcpxml` file, the file's path is returned.
    /// For an `dcpxmld` bundle, the bundle's path is returned.
    public var basePath: URL {
        switch self {
        case let .fcpxml(xmlURL):
            return xmlURL
        case let .fcpxmld(bundleURL):
            return bundleURL
        }
    }
    
    /// Resolves the location of the actual XML file.
    public var xmlPath: URL {
        switch self {
        case let .fcpxml(xmlURL):
            return xmlURL
        case let .fcpxmld(bundleURL):
            return bundleURL.appendingPathComponent("Info.fcpxml")
        }
    }
}
