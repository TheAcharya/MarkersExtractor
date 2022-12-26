import AVFoundation
import AppKit
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

public final class MarkersExtractor {
    private let logger = Logger(label: "\(MarkersExtractor.self)")
    private let s: MarkersExtractorSettings

    init(_ settings: MarkersExtractorSettings) {
        s = settings
    }

    public static func extract(_ settings: MarkersExtractorSettings) throws {
        try self.init(settings).run()
    }

    func run() throws {
        let imageQuality = Double(s.imageQuality) / 100
        let imageLabelFontAlpha = Double(s.imageLabelFontOpacity) / 100
        let imageLabels = OrderedSet(s.imageLabels).map { $0 }
        let imageFormatEXT = s.imageFormat.rawValue.uppercased()

        logger.info("Extracting markers from '\(s.fcpxmlPath.path)'")

        let markers = try extractMarkers()
        
        guard !markers.isEmpty else {
            logger.info("No markers found.")
            return
        }

        let projectName = markers[0].parentProjectName

        let destPath = try makeDestPath(for: projectName)

        let videoPath = try findMedia(name: projectName, path: s.mediaSearchPath)

        logger.info("Found project media file '\(videoPath.path)'")
        logger.info("Generating CSV with \(imageFormatEXT) images into '\(destPath.path)'")

        let labelProperties = MarkerLabelProperties(
            fontName: s.imageLabelFont,
            fontMaxSize: s.imageLabelFontMaxSize,
            fontColor: NSColor(hexString: s.imageLabelFontColor, alpha: imageLabelFontAlpha),
            fontStrokeColor: NSColor(
                hexString: s.imageLabelFontStrokeColor,
                alpha: imageLabelFontAlpha
            ),
            fontStrokeWidth: s.imageLabelFontStrokeWidth,
            alignHorizontal: s.imageLabelAlignHorizontal,
            alignVertical: s.imageLabelAlignVertical
        )

        let csvName = "\(projectName).csv"

        do {
            try markersToCSV(
                markers: markers,
                csvPath: destPath.appendingPathComponent(csvName),
                videoPath: videoPath,
                destPath: destPath,
                gifFPS: s.gifFPS,
                gifSpan: s.gifSpan,
                imageFormat: s.imageFormat,
                imageQuality: imageQuality,
                imageDimensions: calcVideoDimensions(for: videoPath),
                imageLabelFields: imageLabels,
                imageLabelCopyright: s.imageLabelCopyright,
                imageLabelProperties: labelProperties
            )
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to export CSV: \(error.localizedDescription)"
            )
        }

        if s.createDoneFile {
            logger.info("Creating 'done.txt' file at \(destPath.path)")
            try saveDoneFile(at: destPath, text: csvName)
        }

        logger.info("Done!")
    }

    private func extractMarkers(sort: Bool = true) throws -> [Marker] {
        var markers: [Marker]

        do {
            markers = try FCPXMLMarkerExtractor.extractMarkers(
                from: s.xmlPath,
                idNamingMode: s.idNamingMode
            )
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to parse '\(s.xmlPath.path)': \(error.localizedDescription)"
            )
        }

        if !isAllUniqueIDs(in: markers) {
            throw MarkersExtractorError.runtimeError("Every marker must have non-empty ID.")
        }

        // TODO: duplicate markers shouldn't be an error condition, we should append filename uniquing string to the ID instead
        let duplicates = findDuplicateIDs(in: markers)
        if !duplicates.isEmpty {
            throw MarkersExtractorError.runtimeError("Duplicate marker IDs found: \(duplicates)")
        }
        
        if sort {
            markers.sort()
        }

        return markers
    }

    private func findDuplicateIDs(in markers: [Marker]) -> [String] {
        Dictionary(grouping: markers, by: \.id)
            .filter { $1.count > 1 }
            .compactMap { $0.1.first }
            .map { $0.id }
            .sorted()
    }

    private func isAllUniqueIDs(in markers: [Marker]) -> Bool {
        markers.map { $0.id }.allSatisfy { !$0.isEmpty }
    }

    private func makeDestPath(for projectName: String) throws -> URL {
        let destPath = s.outputDir.appendingPathComponent(
            "\(projectName) \(nowTimestamp())"
        )

        do {
            // TODO: this should throw an error if the folder already exists; this folder should be created new every time
            try FileManager.default.mkdirWithParent(destPath.path)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to create destination dir '\(destPath.path)': \(error.localizedDescription)"
            )
        }

        return destPath
    }

    private func saveDoneFile(at destPath: URL, text: String) throws {
        let doneFile = destPath.appendingPathComponent("done.txt")

        do {
            try text.write(to: doneFile, atomically: true, encoding: .utf8)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to create done file '\(doneFile.path)': \(error.localizedDescription)"
            )
        }
    }

    private func findMedia(name: String, path: URL) throws -> URL {
        var files: [URL] = []
        let mediaFormats = ["mov", "mp4", "m4v", "mxf", "avi", "mts", "m2ts", "3gp"]

        do {
            files = try matchFiles(at: path, name: name, exts: mediaFormats)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Error finding media for '\(name)': \(error.localizedDescription)"
            )
        }

        if files.isEmpty {
            throw MarkersExtractorError.runtimeError("No media found for '\(name)'")
        }

        if files.count > 1 {
            logger.warning("Found more than one media candidate for '\(name)'")
        }

        return files[0]
    }

    private func matchFiles(at path: URL, name: String, exts: [String]) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            .filter {
                $0.lastPathComponent.starts(with: name) && exts.contains($0.fileExtension)
            }
    }

    private func nowTimestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh-mm-ss"
        return formatter.string(from: now)
    }

    private func calcVideoDimensions(for videoPath: URL) -> CGSize? {
        if s.imageWidth != nil || s.imageHeight != nil {
            return CGSize(width: s.imageWidth ?? 0, height: s.imageHeight ?? 0)
        } else if let imageSizePercent = s.imageSizePercent {
            return calcVideosSizePercent(at: videoPath, for: imageSizePercent)
        }

        return nil
    }

    private func calcVideosSizePercent(at path: URL, for percent: Int) -> CGSize? {
        let asset = AVAsset(url: path)
        let ratio = Double(percent) / 100

        guard let origDimensions = asset.firstVideoTrack?.dimensions else {
            return nil
        }

        return origDimensions * ratio
    }
}
