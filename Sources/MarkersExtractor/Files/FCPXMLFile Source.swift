//
//  FCPXMLFile Source.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

extension FCPXMLFile {
    public enum Source {
        case fileOnDisk(FilePath)
        case rawFileContents
        case xmlDocument(XMLDocument)
    }
}

extension FCPXMLFile.Source: Equatable { }

extension FCPXMLFile.Source: Hashable { }

extension FCPXMLFile.Source: Identifiable {
    public var id: Self { self }
}

// Using @unchecked to allow use of non-Sendable XMLDocument,
// which should be safe since we only ever read and never write to it
extension FCPXMLFile.Source: @unchecked Sendable { }
