import AVFoundation
import Foundation
import OrderedCollections
import TimecodeKit

/// Generate animated images on disk.
/// For the time being, the only format supported is Animated GIF.
func writeAnimatedImages(
    timecodes: OrderedDictionary<String, Timecode>,
    video videoPath: URL,
    destPath: URL,
    gifFrameRate: Int,
    gifSpan: TimeInterval,
    gifDimensions: CGSize?,
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

    for (imageName, timecode) in timecodes {
        let gifPath = destPath.appendingPathComponent(imageName)

        let timePoint = timecode.realTimeValue
        let gifSpan = gifSpan / 2
        let timeRange = (timePoint - gifSpan)...(timePoint + gifSpan)

        imageLabeler?.nextText()

        let conversion = ImageExtractorGIF.Conversion(
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
