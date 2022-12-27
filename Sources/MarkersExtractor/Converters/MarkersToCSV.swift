import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

func markersToCSV(
    markers: [Marker],
    csvPath: URL,
    videoPath: URL,
    destPath: URL,
    gifFPS: Double,
    gifSpan: TimeInterval,
    imageFormat: MarkerImageFormat,
    imageQuality: Double,
    imageDimensions: CGSize?,
    imageLabelFields: [MarkerHeader],
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

    let markersDicts = markers.map { markerToDict($0, imageFormat, isSingleFrame) }

    logger.info("Exporting marker icons")

    do {
        try exportIcons(from: markers, to: destPath)
    } catch {
        throw MarkersExtractorError.runtimeError("Failed to write marker icons")
    }

    logger.info("Generating \(imageFormat.rawValue.uppercased()) images for markers")

    let imageLabelText = makeImageLabelText(
        markersDicts: markersDicts,
        imageLabelFields: imageLabelFields,
        imageLabelCopyright: imageLabelCopyright
    )

    let timecodes = makeTimecodes(
        markers: markers,
        markersDicts: markersDicts,
        isVideoPresent: isVideoPresent,
        isSingleFrame: isSingleFrame
    )

    if imageFormat == .gif {
        try writeAnimatedImages(
            timecodes: timecodes,
            video: videoPath,
            destPath: destPath,
            gifFPS: gifFPS,
            gifSpan: gifSpan,
            gifDimensions: imageDimensions,
            imageLabelText: imageLabelText,
            imageLabelProperties: imageLabelProperties
        )
    } else {
        try writeStillImages(
            timecodes: timecodes,
            video: videoPath,
            destPath: destPath,
            imageFormat: imageFormat,
            imageJPGQuality: imageQuality,
            imageDimensions: imageDimensions,
            imageLabelText: imageLabelText,
            imageLabelProperties: imageLabelProperties
        )
    }

    let rows = dictsToRows(markersDicts)

    try CSVWriter.encode(rows: rows, into: csvPath, append: false)
}

private func markerToDict(
    _ marker: Marker,
    _ imageFormat: MarkerImageFormat,
    _ isSingleFrame: Bool
) -> OrderedDictionary<MarkerHeader, String> {
    [
        .id: marker.id,
        .name: marker.name,
        .type: marker.type.rawValue,
        .checked: String(marker.checked),
        .status: marker.status.rawValue,
        .notes: marker.notes,
        .position: marker.timecode,
        .clipName: marker.parentClipName,
        .clipDuration: marker.parentClipDurationTimecode,
        .role: marker.role,
        .eventName: marker.parentEventName,
        .projectName: marker.parentProjectName,
        .libraryName: marker.parentLibraryName,
        .iconImage: marker.icon.fileName,
        .imageName: isSingleFrame
            ? "marker-placeholder.\(imageFormat)" : "\(marker.idPathSafe).\(imageFormat)",
    ]
}

private func makeImageLabelText(
    markersDicts: [OrderedDictionary<MarkerHeader, String>],
    imageLabelFields: [MarkerHeader],
    imageLabelCopyright: String?
) -> [String] {
    var imageLabelText: [String] = []

    if !imageLabelFields.isEmpty {
        imageLabelText.append(
            contentsOf: makeLabels(headers: imageLabelFields, markerDicts: markersDicts)
        )
    }

    if let copyrightText = imageLabelCopyright {
        if imageLabelText.isEmpty {
            imageLabelText = markersDicts.map { _ in copyrightText }
        } else {
            imageLabelText = imageLabelText.map { "\($0)\n\(copyrightText)" }
        }
    }

    return imageLabelText
}

private func makeLabels(
    headers: [MarkerHeader],
    markerDicts: [OrderedDictionary<MarkerHeader, String>]
) -> [String] {
    markerDicts.map {
        dictionary in
        headers.map { "\($0.rawValue): \(dictionary[$0]!)" }.joined(separator: "\n")
    }
}

private func makeTimecodes(
    markers: [Marker],
    markersDicts: [OrderedDictionary<MarkerHeader, String>],
    isVideoPresent: Bool,
    isSingleFrame: Bool
) -> OrderedDictionary<String, Timecode> {
    let markerNames = markersDicts.map { $0[.imageName]! }

    // if no video - grabbing first frame from video placeholder
    let markerTimecodes = markers.map {
        isVideoPresent ? $0.position : .init(at: $0.frameRate)
    }

    var markerPairs = zip(markerNames, markerTimecodes).map { ($0, $1) }

    // if no video and no labels - only one frame needed for all markers
    if isSingleFrame {
        markerPairs = [markerPairs[0]]
    }

    return OrderedDictionary(uniqueKeysWithValues: markerPairs)
}

private func dictsToRows(
    _ dicts: [OrderedDictionary<MarkerHeader, String>]
) -> [[String]] {
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
