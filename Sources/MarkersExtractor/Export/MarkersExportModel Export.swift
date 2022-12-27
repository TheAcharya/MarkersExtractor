import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension MarkersExportModel {
    static func export(
        markers: [Marker],
        videoPath: URL,
        outputPath: URL,
        payload: Payload,
        imageSettings: MarkersExportImageSettings<Field>
    ) throws {
        let logger = Logger(label: "markersExport")
        
        var videoPath: URL = videoPath
        let videoPlaceholder: TemporaryMediaFile
        
        let isVideoPresent = isVideoPresent(in: videoPath)
        let isSingleFrame = !isVideoPresent
            && imageSettings.labelFields.isEmpty
            && imageSettings.labelCopyright == nil
        
        if !isVideoPresent {
            logger.info("Media file has no video track, using video placeholder for markers.")
            
            videoPlaceholder = try TemporaryMediaFile(withData: markerVideoPlaceholder)
            videoPath = videoPlaceholder.url!
        }
        
        // Prepare markers
        
        let preparedMarkers = prepareMarkers(
            markers: markers,
            payload: payload,
            imageSettings: imageSettings,
            isSingleFrame: isSingleFrame
        )
        
        logger.info("Exporting marker icons.")
        
        do {
            try exportIcons(from: markers, to: outputPath)
        } catch {
            throw MarkersExtractorError.runtimeError("Failed to write marker icons.")
        }
        
        logger.info("Generating \(imageSettings.format.rawValue.uppercased()) images for markers")
        
        let imageLabelText = makeImageLabelText(
            preparedMarkers: preparedMarkers,
            imageLabelFields: imageSettings.labelFields,
            imageLabelCopyright: imageSettings.labelCopyright
        )
        
        let timecodes = makeTimecodes(
            markers: markers,
            preparedMarkers: preparedMarkers,
            isVideoPresent: isVideoPresent,
            isSingleFrame: isSingleFrame
        )
        
        switch imageSettings.format {
        case .still(let stillImageFormat):
            try writeStillImages(
                timecodes: timecodes,
                video: videoPath,
                destPath: outputPath,
                imageFormat: stillImageFormat,
                imageJPGQuality: imageSettings.quality,
                imageDimensions: imageSettings.dimensions,
                imageLabelText: imageLabelText,
                imageLabelProperties: imageSettings.labelProperties
            )
        case .animated(let animatedImageFormat):
            try writeAnimatedImages(
                timecodes: timecodes,
                video: videoPath,
                destPath: outputPath,
                gifFPS: imageSettings.gifFPS,
                gifSpan: imageSettings.gifSpan,
                gifDimensions: imageSettings.dimensions,
                imageFormat: animatedImageFormat,
                imageLabelText: imageLabelText,
                imageLabelProperties: imageSettings.labelProperties
            )
        }
        
        try encodeManifest(preparedMarkers, payload: payload)
    }
    
    private static func makeImageLabelText(
        preparedMarkers: [PreparedMarker],
        imageLabelFields: [Field],
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
    
    private static func makeLabels(
        headers: [Field],
        preparedMarkers: [PreparedMarker]
    ) -> [String] {
        preparedMarkers
            .map { $0.dictionaryRepresentation() }
            .map { markerDict in
                headers
                    .map { "\($0.rawValue): \(markerDict[$0] ?? "")" }
                    .joined(separator: "\n")
            }
    }
    
    /// Returns an ordered dictionary keyed by marker image filename with a value of timecode position.
    private static func makeTimecodes(
        markers: [Marker],
        preparedMarkers: [PreparedMarker],
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
    
    private static func exportIcons(from markers: [Marker], to distDir: URL) throws {
        let icons = Set(markers.map { $0.icon })
        
        for icon in icons {
            let iconURL = distDir.appendingPathComponent(icon.fileName)
            try icon.bin.write(to: iconURL)
        }
    }
    
    private static func isVideoPresent(in videoPath: URL) -> Bool {
        let asset = AVAsset(url: videoPath)
        
        return asset.firstVideoTrack != nil
    }
}
