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

    public subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get {
            metadata[key]
        }
        set {
            metadata[key] = newValue
        }
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        file: String,
        function: String,
        line: UInt
    ) {
        DispatchQueue.main.async {
            if level == .info {
                print("\(message)")
            } else {
                print("\(level.rawValue.uppercased()): \(message)")
            }
        }
    }
}
