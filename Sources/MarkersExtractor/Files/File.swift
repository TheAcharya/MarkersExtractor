//
//  File.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct File {
    public var cache: FileCache?
    public var url: URL?
}

extension File {
    public enum FileCache {
        /// Pre-fetched file contents as `Data`.
        case data(Data)
        
        /// Pre-fetched file contents as `String`.
        case string(String)
    }
}

extension File {
    public var isFetched: Bool {
        cache != nil
    }
    
    /// Reads the data off disk and returns a new instance containing the cached data.
    /// If the current instance already contains cached data
    public func fetch(resetCache: Bool = false) throws -> Self {
        var copy = self
        
        if resetCache {
            copy.cache = nil
        }
        
        if cache != nil {
            return copy
        }
        
        guard let url = url else {
            throw MarkersExtractorError.runtimeError(
                "File URL is missing while attempting to read file contents."
            )
        }
        
        let data = try Data(contentsOf: url)
        copy.cache = .data(data)
        return copy
    }
    
    public func data() throws -> Data {
        guard let fetched = try fetch().cache else {
            // swiftlint:disable:next force_cast
            let u = url != nil ? "\(url!)" : "-"
            throw MarkersExtractorError.runtimeError("File \(u.quoted) could not be read.")
        }
        switch fetched {
        case let .data(data):
            return data
        case let .string(string):
            guard let data = string.data(using: .utf8) else {
                // swiftlint:disable:next force_cast
                let u = url != nil ? "\(url!)" : "-"
                throw MarkersExtractorError.runtimeError("File \(u.quoted) could not be read.")
            }
            return data
        }
    }
}

// MARK: - Static Constructors

extension File {
    public init(_ url: URL) {
        cache = nil
        self.url = url
    }
    
    public init(fileContents: Data) {
        cache = .data(fileContents)
        url = nil
    }
    
    public init(fileContents: String) {
        cache = .string(fileContents)
        url = nil
    }
    
    public static func fileContents(_ contents: Data) -> Self {
        File(cache: .data(contents), url: nil)
    }
    
    public static func fileContents(_ contents: String) -> Self {
        File(cache: .string(contents), url: nil)
    }
}
