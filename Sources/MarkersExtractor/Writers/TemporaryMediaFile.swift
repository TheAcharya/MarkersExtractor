//
//  TemporaryMediaFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVKit
import Foundation

class TemporaryMediaFile {
    let url: URL
    
    init(withData: Data) throws {
        let directory = FileManager.default.temporaryDirectory
        let fileName = "\(NSUUID().uuidString).mov"
        let url = directory.appendingPathComponent(fileName)
        do {
            try withData.write(to: url)
            self.url = url
        } catch {
            throw MarkersExtractorError.extraction(
                .fileWrite("Error creating temporary file: \(error)")
            )
        }
    }
    
    deinit {
        deleteFile()
    }
}

extension TemporaryMediaFile {
    var avAsset: AVAsset? {
        AVAsset(url: url)
    }
    
    private func deleteFile() {
        try? FileManager.default.removeItem(at: url)
    }
}
