//
//  FCPXMLFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct FCPXMLFile {
    private var inputFile: File
    
    public init(_ inputFile: File) {
        self.inputFile = inputFile
    }
    
    public init(_ url: URL) {
        self.inputFile = File(url)
    }
}

extension FCPXMLFile: CustomStringConvertible {
    public var description: String {
        if let url = inputFile.url {
            return "\(url.path.quoted)"
        }
        
        if inputFile.cache != nil {
            return "FCP XML Data"
        }
        
        return "Missing FCPXML(D) File or Data Contents"
    }
}

extension FCPXMLFile {
    func data() throws -> Data {
        // check for cache data first, or data without a URL
        if let data = try? inputFile.data() {
            return data
        }
            
        guard let xmlPath = xmlPath else {
            throw MarkersExtractorError.runtimeError("Could not read file data.")
        }
        let data = try File(xmlPath).data()
        return data
    }
    
    /// fcpxml(d) file/bundle URL.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var url: URL? {
        inputFile.url
    }
    
    /// Returns the directory that contains the fcpxml(d) file/bundle.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var parentDir: URL? {
        inputFile.url?.deletingLastPathComponent()
    }
    
    /// Resolves the location of the actual XML file.
    /// Returns `nil` if file contents were supplied instead of a URL.
    var xmlPath: URL? {
        guard let url = inputFile.url else {
            // not an error condition; file contents may be cached and no URL is present
            return nil
        }
        
        return url.fileExtension.caseInsensitiveCompare("fcpxmld") == .orderedSame
            ? url.appendingPathComponent("Info.fcpxml")
            : url
    }
    
    var defaultMediaSearchPath: URL? {
        inputFile.url?.deletingLastPathComponent()
    }
}
