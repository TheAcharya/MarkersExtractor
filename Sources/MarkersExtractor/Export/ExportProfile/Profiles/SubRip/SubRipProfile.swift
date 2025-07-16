//
//  SubRipProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public final class SubRipProfile: ExportProfile {
    // ExportProfile
    public typealias Payload = SRTExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = SubRipExportMarker
    public static let profile: ExportProfileFormat = .subrip
    public static let isMediaCapable: Bool = false
    public var logger: Logger?
    
    // Format-specific settings
    public var subtitleDurationSeconds: Double = 1.0
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    public let progress: Progress
    
    public required init(logger: Logger? = nil) {
        self.logger = logger
        progress = Self.defaultProgress
    }
}