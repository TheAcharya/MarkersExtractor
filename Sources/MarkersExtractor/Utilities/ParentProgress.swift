//
//  ParentProgress.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public struct ParentProgress {
    let progress: Progress
    let pendingUnitCount: Int64
    
    init(progress: Progress, unitCount: Int64) {
        self.progress = progress
        pendingUnitCount = unitCount
    }
    
    @_disfavoredOverload
    init(progress: Progress, unitCount: Int) {
        self.progress = progress
        pendingUnitCount = Int64(unitCount)
    }
}

extension ParentProgress: Sendable { }

// MARK: - Methods

extension ParentProgress {
    func addChild(_ child: Progress) {
        progress.addChild(
            child,
            withPendingUnitCount: pendingUnitCount
        )
    }
}
