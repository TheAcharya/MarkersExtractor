//
//  MIDIFileExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public struct MIDIFileExportProfile: ExportProfile {
    public typealias Payload = MIDIFileExportPayload
    public typealias Icon = EmptyExportIcon
    public typealias PreparedMarker = MIDIFileExportMarker
    
    public static let isMediaCapable: Bool = false
    
    public var logger: Logger?
    
    public init(logger: Logger? = nil) {
        self.logger = logger
    }
}
