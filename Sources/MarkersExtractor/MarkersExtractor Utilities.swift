//
//  MarkersExtractor Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import AVFoundation

// MARK: - Output Path

extension MarkersExtractor {
    func makeOutputPath(for projectName: String) throws -> URL {
        let folderName = s.exportFolderFormat.folderName(projectName: projectName, profile: s.exportFormat)
        let outputURL = s.outputDir.appendingPathComponent(folderName)
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
