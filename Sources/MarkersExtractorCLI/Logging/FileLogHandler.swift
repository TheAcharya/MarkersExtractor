//
//  FileLogHandler.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

/// SwiftLog log handler that writes to a text file on disk.
///
/// Derived from https://github.com/crspybits/swift-log-file
public struct FileLogHandler: LogHandler {
    private let stream: FileHandlerOutputStream
    
    private var label: String
    
    public var logLevel: Logger.Level = .info
    
    public var metadata = Logger.Metadata() {
        didSet {
            prettyMetadata = prettify(metadata)
        }
    }
    
    private var prettyMetadata: String?
    
    public init(label: String, localFile url: URL) throws {
        self.label = label
        stream = try FileHandlerOutputStream(localFile: url)
    }
}

extension FileLogHandler: Sendable { }

extension FileLogHandler {
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }
    
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let prettyMetadata = metadata?.isEmpty ?? true
        ? prettyMetadata
        : prettify(self.metadata.merging(metadata!, uniquingKeysWith: { _, new in new }))
        
        var stream = stream
        stream.write(
            "\(timestamp()) \(level):\(prettyMetadata.map { " \($0)" } ?? "") \(message)\n"
        )
    }
    
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        !metadata.isEmpty
        ? metadata.map { "\($0)=\($1)" }.joined(separator: " ")
        : nil
    }
    
    // TODO: Gross. Probably a safer/simpler way to do this.
    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%d %H:%M:%S", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                guard let addr = $0.baseAddress else { return "" }
                return String(cString: addr)
            }
        }
    }
}
