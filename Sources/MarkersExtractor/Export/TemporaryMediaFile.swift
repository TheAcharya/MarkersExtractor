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
        if let url = url {
            return AVAsset(url: url)
        }

        return nil
    }

    public func deleteFile() {
        if let url = url {
            try? FileManager.default.removeItem(at: url)
            self.url = nil
        }
    }

    deinit {
        deleteFile()
    }
}
