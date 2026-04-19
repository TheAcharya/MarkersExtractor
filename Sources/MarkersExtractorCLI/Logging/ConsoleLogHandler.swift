//
//  ConsoleLogHandler.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public struct ConsoleLogHandler: LogHandler {
    private let label: String
    public var logLevel: Logger.Level = .info
    public var metadata: Logger.Metadata = [:]

    public init(label: String) {
        self.label = label
    }
}

extension ConsoleLogHandler: Sendable { }

extension ConsoleLogHandler {
    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }

    public func log(event: LogEvent) {
        DispatchQueue.main.async {
            if event.level == .info {
                print("\(event.message)")
            } else {
                print("\(event.level.rawValue.uppercased()): \(event.message)")
            }
        }
    }
}
