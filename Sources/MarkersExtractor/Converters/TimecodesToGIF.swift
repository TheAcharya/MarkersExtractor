import AVFoundation
import Foundation
import OrderedCollections

func timecodesToGIF(
    timeCodes: OrderedDictionary<String, CMTime>,
    video videoPath: URL,
    destPath: URL,
    gifFrameRate: Int,
    gifSpan: Int,
    gifDimensions: CGSize?,
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

    for (imageName, timeCode) in timeCodes {
        let gifPath = destPath.appendingPathComponent(imageName)

        let timePoint = timeCode.seconds
        let gifSpan = Double(gifSpan) / 2
        let timeRange = (timePoint - gifSpan)...(timePoint + gifSpan)

        imageLabeler?.nextText()

        let conversion = ImageExtractorGIF.Conversion(
            asset: asset,
            sourceURL: videoPath,
            destURL: gifPath,
            timeRange: timeRange,
            dimensions: gifDimensions,
            frameRate: gifFrameRate,
            imageFilter: imageLabeler?.labelImage
        )

        do {
            try ImageExtractorGIF.convert(conversion)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Error while generating gif '\(gifPath.lastPathComponent)':"
                    + " \(error.localizedDescription)"
            )
        }
    }
}
