//
//  TemporaryMediaFile.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVKit
import Foundation

class TemporaryMediaFile {
    var url: URL?

    init(withData: Data) throws {
        let directory = FileManager.default.temporaryDirectory
        let fileName = "\(NSUUID().uuidString).mov"
        let url = directory.appendingPathComponent(fileName)
        do {
            try withData.write(to: url)
            self.url = url
        } catch {
            throw MarkersExtractorError.runtimeError("Error creating temporary file: \(error)")
        }
    }

    public var avAsset: AVAsset? {
        guard let url = url else { return nil }
        return AVAsset(url: url)
    }

    public func deleteFile() {
        guard let url = url else { return }
        try? FileManager.default.removeItem(at: url)
        self.url = nil
    }

    deinit {
        deleteFile()
    }
}
