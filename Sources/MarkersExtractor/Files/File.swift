//
//  File.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Represents a file's contents, either from a file stored on disk or directly from raw data.
/// In either case, the file content is cached in memory to improve performance and reduce
/// unnecessary disk activity.
struct File {
    public private(set) var contents: Contents
}

extension File: Equatable { }

extension File: Hashable { }

extension File: Sendable { }

// MARK: - Init

extension File {
    init(_ url: URL) {
        contents = .fileOnDisk(url: url, cache: nil)
    }
    
    init(fileContents: Contents.Cache) {
        contents = .rawFileContents(fileContents)
    }
}
    
// MARK: - Static Constructors

extension File {
    static func fileContents(_ contents: Contents.Cache) -> Self {
        File(contents: .rawFileContents(contents))
    }
}

// MARK: - Properties

extension File {
    /// Returns a Boolean value indicating whether the file's contents has been read off disk
    /// and cached.
    var isFetched: Bool {
        switch contents {
        case let .fileOnDisk(_, cache):
            return cache != nil
        case .rawFileContents:
            return true
        }
    }
    
    /// Returns file path URL if instance was constructed from an URL.
    /// Always returns `nil` if instances was constructed from raw file contents.
    var url: URL? {
        switch contents {
        case let .fileOnDisk(url, _):
            return url
        case .rawFileContents:
            return nil
        }
    }
    
    /// Reads the data off disk and returns a new instance containing the cached data.
    /// If the current instance already contains cached data, the cache is returned.
    ///
    /// There is no need to call this manually. Calling ``data(resetCache:)`` to retrieve
    /// the file's contents will also fill the cache if needed.
    ///
    /// - Parameters:
    ///   - resetCache: Re-read the file's contents from disk and update the cache regardless of
    /// cache state.
    mutating func fetch(resetCache: Bool = false) throws {
        switch contents {
        case let .fileOnDisk(url, cache):
            if cache != nil, !resetCache { return }
            do {
                let data = try Data(contentsOf: url)
                contents = .fileOnDisk(url: url, cache: .data(data))
            } catch {
                throw MarkersExtractorError.extraction(.fileRead(error.localizedDescription))
            }
        case .rawFileContents:
            // nothing to fetch and resetting cache is meaningless
            return
        }
    }
    
    /// Reads the file's contents off disk and returns it as a new `Data` instance.
    /// After the first access, the file's data is cached so subsequent calls are more performant.
    mutating func data() throws -> Data {
        // update cache if needed
        try fetch()
        
        // retrieve cache
        let unwrappedCache: Contents.Cache
        switch contents {
        case let .fileOnDisk(url, cache):
            guard let cache else {
                throw MarkersExtractorError.extraction(.fileRead(
                    "File could not be read: \(url.path.quoted)."
                ))
            }
            unwrappedCache = cache
            
        case let .rawFileContents(cache):
            unwrappedCache = cache
        }
        
        // convert to Data if needed
        switch unwrappedCache {
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
