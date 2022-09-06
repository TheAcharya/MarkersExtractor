import AVFoundation
import CodableCSV
import Foundation
import Logging
import OrderedCollections

func markersToCSV(
    markers: [Marker],
    csvPath: URL,
    videoPath: URL,
    destPath: URL,
    gifFPS: Int,
    gifSpan: Int,
    imageFormat: MarkerImageFormat,
    imageQuality: Double,
    imageDimensions: CGSize?,
    imageLabelFields: [MarkerHeader],
    imageLabelCopyright: String?,
    imageLabelProperties: MarkerLabelProperties
) throws {
    let logger = Logger(label: "markersToCSV")

    let isVideoPresent = isVideoPresent(in: videoPath)

    let markersDicts = markers.map { markerToDict($0, isVideoPresent ? imageFormat : nil) }

    logger.info("Exporting marker icons")

    do {
        try exportIcons(from: markers, to: destPath)
    } catch {
        throw MarkersExtractorError.runtimeError("Failed to write marker icons")
    }

    if isVideoPresent {
        logger.info("Generating \(imageFormat.rawValue.uppercased()) images for markers")

        let imageLabelText = makeImageLabelText(
            markersDicts: markersDicts,
            imageLabelFields: imageLabelFields,
            imageLabelCopyright: imageLabelCopyright
        )
        let timeCodes = makeTimecodes(markers: markers, markersDicts: markersDicts)

        if imageFormat == .gif {
            try timecodesToGIF(
                timeCodes: timeCodes,
                video: videoPath,
                destPath: destPath,
                gifFrameRate: gifFPS,
                gifSpan: gifSpan,
                gifDimensions: imageDimensions,
                imageLabelText: imageLabelText,
                imageLabelProperties: imageLabelProperties
            )
        } else {
            try timecodesToPIC(
                timeCodes: timeCodes,
                video: videoPath,
                destPath: destPath,
                imageFormat: imageFormat,
                imageJPGQuality: imageQuality,
                imageDimensions: imageDimensions,
                imageLabelText: imageLabelText,
                imageLabelProperties: imageLabelProperties
            )
        }
    } else {
        logger.info("No video track present in \(videoPath.path), skipping images processing")
    }

    let rows = dictsToRows(markersDicts)

    try CSVWriter.encode(rows: rows, into: csvPath, append: false)
}

private func markerToDict(
    _ marker: Marker,
    _ imageFormat: MarkerImageFormat?
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
        .imageName: imageFormat == nil ? "" : "\(marker.idPathSafe).\(imageFormat!)",
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
    markersDicts: [OrderedDictionary<MarkerHeader, String>]
) -> OrderedDictionary<String, CMTime> {
    let markerNames = markersDicts.map { $0[.imageName]! }
    return OrderedDictionary(
        uniqueKeysWithValues: zip(markerNames, markers).map { ($0, $1.position) }
    )
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
