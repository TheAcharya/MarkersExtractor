//
//  ExportResult Value.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

extension ExportResult {
    /// Type-erased box to maintain type safety for the intermediate dictionary.
    public enum Value {
        case date(_ date: Date)
        case string(_ string: String)
        case url(_ url: URL)
        case profile(_ profileFormat: ExportProfileFormat)
    }
}

extension ExportResult.Value: Equatable { }

extension ExportResult.Value: Hashable { }

extension ExportResult.Value: Sendable { }

extension ExportResult.Value {
    public var stringValueForJSON: String {
        switch self {
        case let .date(date):
            return date.formatted(.iso8601)
        case let .string(string):
            return string
        case let .url(url):
            return url.path
        case let .profile(profile):
            return profile.rawValue
        }
    }
}
