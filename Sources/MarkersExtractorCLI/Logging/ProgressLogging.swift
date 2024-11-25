//
//  ProgressLogging.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

/// Observes changes in a `Progress` instance and logs updates to the console.
final actor ProgressLogging {
    let logger: Logger
    let progress: Progress
    private(set) var lastOutput: String?
    
    private var observation: NSKeyValueObservation?
    
    init(to logger: Logger, progress: Progress) {
        self.logger = logger
        self.progress = progress
        
        Task { await setup() }
    }
    
    private func setup() {
        observation = progress
            .observe(\.fractionCompleted, options: [.new]) { [weak self] _, _ in
                Task { await self?.progressChanged() }
            }
    }
    
    private func progressChanged() {
        let output = String(format: "%.0f", progress.fractionCompleted * 100) + "%"
        guard self.lastOutput != output else { return } // suppress redundant output
        self.logger.info("\(output)")
        self.lastOutput = output
    }
}

// TODO: Codable conformance is a workaround to satisfy the compiler so we can store an
// instance of this class in the AsyncParsableCommand struct.
extension ProgressLogging: @preconcurrency Codable {
    func encode(to encoder: Encoder) throws { }
    
    init(from decoder: Decoder) throws {
        let logger = Logger(label: "Dummy")
        let progress = Progress()
        self.init(to: logger, progress: progress)
    }
}

extension ProgressLogging: Sendable { }
