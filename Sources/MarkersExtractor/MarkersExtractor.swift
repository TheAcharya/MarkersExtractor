//
//  MarkersExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

public final class MarkersExtractor {
    var settings: Settings
    public let logger: Logger
    public let progress: Progress
    
    public init(settings: Settings, logger: Logger? = nil) {
        self.settings = settings
        self.logger = logger ?? Logger(label: "\(MarkersExtractor.self)")
        progress = Progress()
    }
}
