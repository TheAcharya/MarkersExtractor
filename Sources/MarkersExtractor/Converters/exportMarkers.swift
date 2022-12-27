import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

/// Exports markers to disk.
/// Writes csv file, images, and any other resources necessary.
func exportMarkers(
    markers: [Marker],
    csvPath: URL,
    videoPath: URL,
    destPath: URL,
    gifFPS: Double,
    gifSpan: TimeInterval,
    imageFormat: MarkerImageFormat,
    imageQuality: Double,
    imageDimensions: CGSize?,
    imageLabelFields: [MarkerCSVHeader],
    imageLabelCopyright: String?,
    imageLabelProperties: MarkerLabelProperties
) throws {
    let logger = Logger(label: "markersToCSV")

    var videoPath: URL = videoPath
    let videoPlaceholder: TemporaryMediaFile

    let isVideoPresent = isVideoPresent(in: videoPath)
    let isSingleFrame = !isVideoPresent && imageLabelFields.isEmpty && imageLabelCopyright == nil

    if !isVideoPresent {
        logger.info("Media file has no video track, using video placeholder for markers")

        videoPlaceholder = try TemporaryMediaFile(withData: markerVideoPlaceholder)
        videoPath = videoPlaceholder.url!
    }

    let preparedMarkers = markers.map {
        CSVMarker($0, imageFormat: imageFormat, isSingleFrame: isSingleFrame)
    }

    logger.info("Exporting marker icons")

    do {
        try exportIcons(from: markers, to: destPath)
    } catch {
        throw MarkersExtractorError.runtimeError("Failed to write marker icons")
    }

    logger.info("Generating \(imageFormat.rawValue.uppercased()) images for markers")

    let imageLabelText = makeImageLabelText(
        preparedMarkers: preparedMarkers,
        imageLabelFields: imageLabelFields,
        imageLabelCopyright: imageLabelCopyright
    )

    let timecodes = makeTimecodes(
        markers: markers,
        preparedMarkers: preparedMarkers,
        isVideoPresent: isVideoPresent,
        isSingleFrame: isSingleFrame
    )

    switch imageFormat {
    case .still(let stillImageFormat):
        try writeStillImages(
            timecodes: timecodes,
            video: videoPath,
            destPath: destPath,
            imageFormat: stillImageFormat,
            imageJPGQuality: imageQuality,
            imageDimensions: imageDimensions,
            imageLabelText: imageLabelText,
            imageLabelProperties: imageLabelProperties
        )
    case .animated(let animatedImageFormat):
        try writeAnimatedImages(
            timecodes: timecodes,
            video: videoPath,
            destPath: destPath,
            gifFPS: gifFPS,
            gifSpan: gifSpan,
            gifDimensions: imageDimensions,
            imageFormat: animatedImageFormat,
            imageLabelText: imageLabelText,
            imageLabelProperties: imageLabelProperties
        )
    }

    let rows = dictsToRows(preparedMarkers)

    let csvData = try CSVWriter.encode(rows: rows, into: Data.self)
    try csvData.write(to: csvPath)
}

private func makeImageLabelText(
    preparedMarkers: [CSVMarker],
    imageLabelFields: [MarkerCSVHeader],
    imageLabelCopyright: String?
) -> [String] {
    var imageLabelText: [String] = []

    if !imageLabelFields.isEmpty {
        imageLabelText.append(
            contentsOf: makeLabels(headers: imageLabelFields, preparedMarkers: preparedMarkers)
        )
    }

    if let copyrightText = imageLabelCopyright {
        if imageLabelText.isEmpty {
            imageLabelText = preparedMarkers.map { _ in copyrightText }
        } else {
            imageLabelText = imageLabelText.map { "\($0)\n\(copyrightText)" }
        }
    }

    return imageLabelText
}

private func makeLabels(
    headers: [MarkerCSVHeader],
    preparedMarkers: [CSVMarker]
) -> [String] {
    preparedMarkers
        .map { $0.dictionaryRepresentation() }
        .map { csvMarkerDict in
            headers
                .map { "\($0.rawValue): \(csvMarkerDict[$0] ?? "")" }
                .joined(separator: "\n")
        }
}

/// Returns an ordered dictionary keyed by marker image filename with a value of timecode position.
private func makeTimecodes(
    markers: [Marker],
    preparedMarkers: [CSVMarker],
    isVideoPresent: Bool,
    isSingleFrame: Bool
) -> OrderedDictionary<String, Timecode> {
    let imageFileNames = preparedMarkers.map { $0.imageFileName }

    // if no video - grabbing first frame from video placeholder
    let markerTimecodes = markers.map {
        isVideoPresent ? $0.position : .init(at: $0.frameRate)
    }

    var markerPairs = zip(imageFileNames, markerTimecodes).map { ($0, $1) }

    // if no video and no labels - only one frame needed for all markers
    if isSingleFrame {
        markerPairs = [markerPairs[0]]
    }

    return OrderedDictionary(uniqueKeysWithValues: markerPairs)
}

private func dictsToRows(
    _ preparedMarkers: [CSVMarker]
) -> [[String]] {
    let dicts = preparedMarkers.map { $0.dictionaryRepresentation() }
    guard !dicts.isEmpty else { return [] }
    
    var result = [Array(dicts[0].keys.map { $0.rawValue })]

    for row in dicts {
        result += [Array(row.values)]
    }

    return result
}

private func exportIcons(from markers: [Marker], to distDir: URL) throws {
    let icons = Set(markers.map { $0.icon })

    for icon in icons {
        let iconURL = distDir.appendingPathComponent(icon.fileName)
        try icon.bin.write(to: iconURL)
    }
}

private func isVideoPresent(in videoPath: URL) -> Bool {
    let asset = AVAsset(url: videoPath)

    return asset.firstVideoTrack != nil
}
