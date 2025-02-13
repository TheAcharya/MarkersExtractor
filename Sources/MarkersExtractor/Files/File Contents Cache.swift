//
//  File Contents Cache.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension File.Contents {
    /// Type-erased ``File`` contents cache.
    enum Cache {
        /// Pre-fetched file contents as `Data`.
        case data(Data)
        
        /// Pre-fetched file contents as `String`.
        case string(String)
    }
}

extension File.Contents.Cache: Equatable { }

extension File.Contents.Cache: Hashable { }

extension File.Contents.Cache: Sendable { }
