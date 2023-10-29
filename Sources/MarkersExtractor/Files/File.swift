//
//  File.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Represents a file's contents, either in memory or from a file stored on disk.
/// In either case, the file content is cached in memory to improve performance and reduce
/// unnecessary disk activity.
internal struct File {
    public var cache: FileContentsCache?
    public var url: URL?
}

// MARK: - Constructors

extension File {
    public init(_ url: URL) {
        cache = nil
        self.url = url
    }
    
    public init(fileContents: FileContentsCache) {
        cache = fileContents
        url = nil
    }
    
    public static func fileContents(_ contents: FileContentsCache) -> Self {
        File(cache: contents, url: nil)
    }
}

extension File {
    /// Type-erased ``File`` contents cache.
    public enum FileContentsCache {
        /// Pre-fetched file contents as `Data`.
        case data(Data)
        
        /// Pre-fetched file contents as `String`.
        case string(String)
    }
}

extension File {
    /// Returns a Boolean value indicating whether the file's contents has been read off disk
    /// and cached.
    public var isFetched: Bool {
        cache != nil
    }
    
    /// Reads the data off disk and returns a new instance containing the cached data.
    /// If the current instance already contains cached data, the cache is returned.
    ///
    /// There is no need to call this manually. Calling ``data(resetCache:)`` to retrieve
    /// the file's contents will also fill the cache if needed.
    ///
    /// - Parameters:
    ///   - resetCache: Force the cache to reset (flush) and re-read the file's contents from disk.
    public func fetch(resetCache: Bool = false) throws -> Self {
        var copy = self
        
        if resetCache {
            copy.cache = nil
        }
        
        if cache != nil {
            return copy
        }
        
        guard let url = url else {
            throw MarkersExtractorError.extraction(.fileRead(
                "File URL is missing while attempting to read file contents."
            ))
        }
        
        let data = try Data(contentsOf: url)
        copy.cache = .data(data)
        return copy
    }
    
    /// Reads the file's contents off disk and returns it as a new `Data` instance.
    /// After the first access, the file's data is cached so subsequent calls are more performant.
    ///
    /// - Parameters:
    ///   - resetCache: Force the cache to reset (flush) and re-read the file's contents from disk.
    /// - Returns: File contents.
    public func data(resetCache: Bool = false) throws -> Data {
        let fetched = try fetch(resetCache: resetCache)
        guard let contents = fetched.cache else {
            // swiftlint:disable:next force_cast
            if let url {
                throw MarkersExtractorError.extraction(.fileRead(
                    "File could not be read: \(url.path.quoted)."
                ))
            } else {
                throw MarkersExtractorError.extraction(.fileRead(
                    "File could not be read."
                ))
            }
        }
        switch contents {
        case let .data(data):
            return data
        case let .string(string):
            guard let data = string.data(using: .utf8) else {
                throw MarkersExtractorError.validation(
                    .unsupportedFileFormat(atPath: url?.path)
                )
            }
            return data
        }
    }
}
