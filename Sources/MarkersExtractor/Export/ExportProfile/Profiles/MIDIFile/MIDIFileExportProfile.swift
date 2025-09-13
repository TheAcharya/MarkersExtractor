//
//  MIDIFileExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public final class MIDIFileExportProfile: ExportProfile {
    // ExportProfile
    public typealias Payload = MIDIFileExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = MIDIFileExportMarker
    public static let profile: ExportProfileFormat = .midi
    public static let isMediaCapable: Bool = false
    public let logger: Logger?
    
    // ProgressReporting (omitted protocol conformance as it would force NSObject inheritance)
    public let progress: Progress
    
    public required init(logger: Logger? = nil) {
        self.logger = logger
        progress = Self.defaultProgress
    }
}
