//
//  ProgressLogging.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

/// Observes changes in a `Progress` instance and logs updates to the console.
/// Codable conformance is a workaround to satisfy the compiler so we can store an
/// instance of this class in the AsyncParsableCommand struct.
final class ProgressLogging: NSObject, Codable {
    var logger: Logger
    var progress: Progress
    var observation: NSKeyValueObservation?
    
    var lastOutput: String?
    
    init(to logger: Logger, progress: Progress) {
        self.logger = logger
        self.progress = progress
        
        super.init()
        
        observation = progress
            .observe(\.fractionCompleted, options: [.new]) { [weak self] _, _ in
                guard let self else { return }
                self.progressChanged()
            }
    }
    
    private func progressChanged() {
        let output = String(format: "%.0f", progress.fractionCompleted * 100) + "%"
        guard self.lastOutput != output else { return } // suppress redundant output
        self.logger.info("\(output)")
        self.lastOutput = output
    }
    
    func encode(to encoder: Encoder) throws { }
    
    init(from decoder: Decoder) throws {
        logger = Logger(label: "Dummy")
        progress = Progress()
    }
}
