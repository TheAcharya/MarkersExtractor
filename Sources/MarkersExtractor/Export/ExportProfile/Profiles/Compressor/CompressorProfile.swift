//
//  CompressorProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public final class CompressorProfile: ExportProfile {
    // ExportProfile
    public typealias Payload = TextExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = StandardExportMarker
    public static let profile: ExportProfileFormat = .compressor
    public static let isMediaCapable: Bool = false
    public var logger: Logger?
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    public let progress: Progress
    
    public required init(logger: Logger? = nil) {
        self.logger = logger
        progress = Self.defaultProgress
    }
}
