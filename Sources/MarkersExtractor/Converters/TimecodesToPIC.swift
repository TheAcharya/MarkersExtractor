import AVFoundation
import Foundation
import OrderedCollections

func timecodesToPIC(
    timeCodes: OrderedDictionary<String, CMTime>,
    video videoPath: URL,
    destPath: URL,
    imageFormat: MarkerImageFormat,
    imageJPGQuality: Double,
    imageDimensions: CGSize?,
    imageLabelText: [String],
    imageLabelProperties: MarkerLabelProperties
) throws {
    let asset = AVAsset(url: videoPath)

    var imageLabeler: ImageLabeler? = nil

    if !imageLabelText.isEmpty {
        imageLabeler = ImageLabeler(
            labelText: imageLabelText,
            labelProperties: imageLabelProperties
        )
    }

    let conversion = ImageExtractor.Conversion(
        asset: asset,
        sourceURL: videoPath,
        destURL: destPath,
        timeCodes: timeCodes,
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
