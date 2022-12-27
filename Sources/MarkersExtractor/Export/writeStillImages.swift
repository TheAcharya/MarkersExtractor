import AVFoundation
import Foundation
import OrderedCollections
import TimecodeKit

func writeStillImages(
    timecodes: OrderedDictionary<String, Timecode>,
    video videoPath: URL,
    destPath: URL,
    imageFormat: MarkerImageFormat.Still,
    imageJPGQuality: Double,
    imageDimensions: CGSize?,
    imageLabelText: [String],
    imageLabelProperties: MarkerLabelProperties
) throws {
    var imageLabeler: ImageLabeler? = nil

    if !imageLabelText.isEmpty {
        imageLabeler = ImageLabeler(
            labelText: imageLabelText,
            labelProperties: imageLabelProperties
        )
    }

    let conversion = ImageExtractor.ConversionSettings(
        sourceURL: videoPath,
        destURL: destPath,
        timecodes: timecodes,
        frameFormat: imageFormat,
        frameJPGQuality: imageJPGQuality,
        dimensions: imageDimensions,
        imageFilter: imageLabeler?.labelImageNextText
    )

    do {
        try ImageExtractor.convert(conversion)
    } catch {
        throw MarkersExtractorError.runtimeError(
            "Error while generating images: \(error.localizedDescription)"
        )
    }
}
