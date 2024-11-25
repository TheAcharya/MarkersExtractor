//
//  MarkersExtractor Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import OTCore

// MARK: - Output Path

extension MarkersExtractor {
    func makeOutputPath(forTimelineName timelineName: String) throws -> URL {
        let folderName = s.exportFolderFormat.folderName(
            timelineName: timelineName,
            profile: s.exportFormat
        )
        let proposedOutputURL = s.outputDir.appendingPathComponent(folderName)
        let outputURL = FileManager.default.uniqueFileURL(proposedPath: proposedOutputURL)
        try FileManager.default.mkdirWithParent(outputURL.path, reuseExisting: false)
        
        return outputURL
    }
}

// MARK: - Helpers

extension MarkersExtractor {
    func calcVideoDimensions(for videoPath: URL) -> CGSize? {
        if s.imageWidth != nil || s.imageHeight != nil {
            return CGSize(width: s.imageWidth ?? 0, height: s.imageHeight ?? 0)
        } else if let imageSizePercent = s.imageSizePercent {
            return calcVideosSizePercent(at: videoPath, for: imageSizePercent)
        }
        
        return nil
    }
    
    func calcVideosSizePercent(at path: URL, for percent: Int) -> CGSize? {
        let asset = AVAsset(url: path)
        let ratio = Double(percent) / 100
        
        guard let origDimensions = asset.firstVideoTrack?.dimensions else {
            return nil
        }
        
        return origDimensions * ratio
    }
}

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
    
    func addChild(_ child: Progress) {
        progress.addChild(
            child,
            withPendingUnitCount: pendingUnitCount
        )
    }
}

actor Counter: Sendable {
    private(set) var count: Int
    private let onUpdate: ((_ count: Int) -> Void)?
    
    init(count: Int, onUpdate: ((_ count: Int) -> Void)? = nil) {
        self.count = count
        self.onUpdate = onUpdate
    }
    
    func increment() { setCount(count + 1) }
    func decrement() { setCount(count - 1) }
    func setCount(_ count: Int) {
        self.count = count
        onUpdate?(count)
    }
}
