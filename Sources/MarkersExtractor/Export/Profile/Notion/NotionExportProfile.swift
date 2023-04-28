//
//  NotionExportProfile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public struct NotionExportProfile: ExportProfile {
    public typealias Payload = CSVExportPayload
    public typealias PreparedMarker = StandardExportMarker
    
    public static let isMediaCapable: Bool = true
    
    public var logger: Logger?
    
    public init(logger: Logger? = nil) {
        self.logger = logger
    }
}
