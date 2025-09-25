//
//  NotionExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public final class NotionExportProfile: ExportProfile {
    // ExportProfile
    public typealias Payload = JSONExportPayload
    public typealias PreparedMarker = StandardExportMarker
    public static let profile: ExportProfileFormat = .notion
    public static let isMediaCapable: Bool = true
    public var logger: Logger?
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    public let progress: Progress
    
    public required init(logger: Logger? = nil) {
        self.logger = logger
        progress = Self.defaultProgress
    }
}
