//
//  MIDIFileExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public class MIDIFileExportProfile: ExportProfile {
    // ExportProfile
    public typealias Payload = MIDIFileExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = MIDIFileExportMarker
    public static let profile: ExportProfileFormat = .midi
    public static let isMediaCapable: Bool = false
    public var logger: Logger?
    
    // ProgressReporting
    public let progress: Progress
    
    public required init(logger: Logger? = nil) {
        self.logger = logger
        progress = Self.defaultProgress
    }
}
