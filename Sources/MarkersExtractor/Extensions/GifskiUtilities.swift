// https://github.com/sindresorhus/Gifski/blob/9a8805ed6392748d9d699a78fbba39e0e77cf64e/Gifski/Utilities.swift
/*
MIT License

© 2019 Sindre Sorhus <sindresorhus@gmail.com> (sindresorhus.com)
© 2019 Kornel Lesiński <kornel@pngquant.org> (gif.ski)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import AVFoundation
import Accelerate.vImage
import Combine
import StoreKit.SKStoreReviewController
import SwiftUI

extension AVAssetImageGenerator {
    struct CompletionHandlerResult {
        let image: CGImage
        let requestedTime: CMTime
        let actualTime: CMTime
        let completedCount: Int
        let totalCount: Int
        let isFinished: Bool
        let isFinishedIgnoreImage: Bool
    }

    /**
     - Note: If you use `result.completedCount`, don't forget to update its usage in each `completionHandler` call as it can change if frames are skipped, for example, blank frames.
     */
    func generateCGImagesAsynchronously(
        forTimePoints timePoints: [CMTime],
        completionHandler: @escaping (Swift.Result<CompletionHandlerResult, Error>) -> Void
    ) {
        let times = timePoints.map { NSValue(time: $0) }
        var totalCount = times.count
        var completedCount = 0
        var decodeFailureFrameCount = 0

        generateCGImagesAsynchronously(forTimes: times) {
            requestedTime,
            image,
            actualTime,
            result,
            error in
            switch result {
            case .succeeded:
                completedCount += 1

                completionHandler(
                    .success(
                        CompletionHandlerResult(
                            image: image!,
                            requestedTime: requestedTime,
                            actualTime: actualTime,
                            completedCount: completedCount,
                            totalCount: totalCount,
                            isFinished: completedCount == totalCount,
                            isFinishedIgnoreImage: false
                        )
                    )
                )
            case .failed:
                // Handles blank frames in the middle of the video.
                // TODO: Report the `xcrun` bug to Apple if it's still an issue in macOS 11.
                if let error = error as? AVError {
                    // Ugly workaround for when the last frame is a failure.
                    func finishWithoutImageIfNeeded() {
                        guard completedCount == totalCount else {
                            return
                        }

                        completionHandler(
                            .success(
                                CompletionHandlerResult(
                                    image: .empty,
                                    requestedTime: requestedTime,
                                    actualTime: actualTime,
                                    completedCount: completedCount,
                                    totalCount: totalCount,
                                    isFinished: true,
                                    isFinishedIgnoreImage: true
                                )
                            )
                        )
                    }

                    // We ignore blank frames.
                    if error.code == .noImageAtTime {
                        totalCount -= 1
                        print("No image at time. Completed: \(completedCount) Total: \(totalCount)")
                        finishWithoutImageIfNeeded()
                        break
                    }

                    // macOS 11 (still an issue in macOS 11.2) started throwing “decode failed” error for some frames in screen recordings. As a workaround, we ignore these as the GIF seems fine still.
                    if error.code == .decodeFailed {
                        decodeFailureFrameCount += 1
                        totalCount -= 1
                        print("Decode failure. Completed: \(completedCount) Total: \(totalCount)")
                        //						Crashlytics.recordNonFatalError(error: error, userInfo: ["requestedTime": requestedTime.seconds])
                        finishWithoutImageIfNeeded()
                        break
                    }
                }

                completionHandler(.failure(error!))
            case .cancelled:
                completionHandler(.failure(CancellationError()))
            @unknown default:
                assertionFailure(
                    "AVAssetImageGenerator.generateCGImagesAsynchronously() received a new enum case. Please handle it."
                )
            }
        }
    }
}

extension CMTimeScale {
    /**
     Apple-recommended scale for video.

     ```
     CMTime(seconds: (1 / fps), preferredTimescale: .video)
     ```
     */
    static let video: Self = 600
}

extension Comparable {
    func clamped(from lowerBound: Self, to upperBound: Self) -> Self {
        min(max(self, lowerBound), upperBound)
    }

    func clamped(to range: ClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }

    func clamped(to range: PartialRangeThrough<Self>) -> Self {
        min(self, range.upperBound)
    }

    func clamped(to range: PartialRangeFrom<Self>) -> Self {
        max(self, range.lowerBound)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to range: CountableRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound.advanced(by: -1))
    }

    func clamped(to range: CountableClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }

    func clamped(to range: PartialRangeUpTo<Self>) -> Self {
        min(self, range.upperBound.advanced(by: -1))
    }
}

extension FixedWidthInteger {
    /**
     Returns the integer formatted as a human readble file size.

     Example: `2.3 GB`
     */
    var bytesFormattedAsFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

extension String.StringInterpolation {
    /**
     Interpolate the value by unwrapping it, and if `nil`, use the given default string.

     ```
     // This doesn't work as you can only use nil coalescing in interpolation with the same type as the optional
     "foo \(optionalDouble ?? "none")

     // Now you can do this
     "foo \(optionalDouble, default: "none")
     ```
     */
    public mutating func appendInterpolation(_ value: Any?, default defaultValue: String) {
        if let value = value {
            appendInterpolation(value)
        } else {
            appendLiteral(defaultValue)
        }
    }

    /**
     Interpolate the value by unwrapping it, and if `nil`, use `"nil"`.

     ```
     // This doesn't work as you can only use nil coalescing in interpolation with the same type as the optional
     "foo \(optionalDouble ?? "nil")

     // Now you can do this
     "foo \(describing: optionalDouble)
     ```
     */
    public mutating func appendInterpolation(describing value: Any?) {
        if let value = value {
            appendInterpolation(value)
        } else {
            appendLiteral("nil")
        }
    }
}

extension Double {
    /**
     Converts the number to a string and strips fractional trailing zeros.

     ```
     let x = 1.0

     print(1.0)
     //=> "1.0"

     print(1.0.formatted)
     //=> "1"

     print(0.0100.formatted)
     //=> "0.01"
     ```
     */
    var formatted: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension CGSize {
    /**
     Example: `140×100`
     */
    var formatted: String { "\(width.double.formatted)×\(height.double.formatted)" }
}

extension NSImage {
    /**
     `UIImage` polyfill.
     */
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
}

extension CGImage {
    var nsImage: NSImage { NSImage(cgImage: self) }
}

extension AVAssetImageGenerator {
    func image(at time: CMTime) -> NSImage? {
        (try? copyCGImage(at: time, actualTime: nil))?.nsImage
    }
}

extension AVAsset {
    func image(at time: CMTime) -> NSImage? {
        let imageGenerator = AVAssetImageGenerator(asset: self)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        return imageGenerator.image(at: time)
    }
}

extension AVAssetTrack {
    enum VideoTrimmingError: Error {
        case unknownAssetReaderFailure
        case videoTrackIsEmpty
        case assetIsMissingVideoTrack
        case compositionCouldNotBeCreated
        case codecNotSupported
    }

    /**
     Removes blank frames from the beginning of the track.

     This can be useful to trim blank frames from files produced by tools like the iOS simulator screen recorder.
     */
    func trimmingBlankFrames() throws -> AVAssetTrack {
        // See https://github.com/sindresorhus/Gifski/issues/254 for context.
        // In short: Some codecs seem to always report a sample buffer size of 0 when reading, breaking this function. (macOS 11.6)
        let buggyCodecs = ["v210", "BGRA"]
        if let codecIdentifier = codecIdentifier,
            buggyCodecs.contains(codecIdentifier)
        {
            throw VideoTrimmingError.codecNotSupported
        }

        // Create new composition
        let composition = AVMutableComposition()
        guard
            let wrappedTrack = composition.addMutableTrack(
                withMediaType: mediaType,
                preferredTrackID: .zero
            )
        else {
            throw VideoTrimmingError.compositionCouldNotBeCreated
        }

        wrappedTrack.preferredTransform = preferredTransform

        try wrappedTrack.insertTimeRange(timeRange, of: self, at: .zero)

        let reader = try AVAssetReader(asset: composition)

        // Create reader for wrapped track.
        let readerOutput = AVAssetReaderTrackOutput(track: wrappedTrack, outputSettings: nil)
        readerOutput.alwaysCopiesSampleData = false

        reader.add(readerOutput)
        reader.startReading()

        defer {
            reader.cancelReading()
        }

        // Iterate through samples until we reach one with a non-zero size.
        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            guard [.completed, .reading].contains(reader.status) else {
                throw reader.error ?? VideoTrimmingError.unknownAssetReaderFailure
            }

            // On first non-empty frame.
            guard sampleBuffer.totalSampleSize == 0 else {
                let currentTimestamp = sampleBuffer.outputPresentationTimeStamp
                wrappedTrack.removeTimeRange(.init(start: .zero, end: currentTimestamp))
                return wrappedTrack
            }
        }

        throw VideoTrimmingError.videoTrackIsEmpty
    }
}

extension AVAssetTrack.VideoTrimmingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unknownAssetReaderFailure:
            return "Asset could not be read."
        case .videoTrackIsEmpty:
            return "Video track is empty."
        case .assetIsMissingVideoTrack:
            return "Asset is missing video track."
        case .compositionCouldNotBeCreated:
            return "Composition could not be created."
        case .codecNotSupported:
            return "Video codec is not supported."
        }
    }
}

extension AVAsset {
    typealias VideoTrimmingError = AVAssetTrack.VideoTrimmingError

    /**
     Removes blank frames from the beginning of the first video track of the asset. The returned asset only includes the first video track.

     This can be useful to trim blank frames from files produced by tools like the iOS simulator screen recorder.
     */
    func trimmingBlankFramesFromFirstVideoTrack() throws -> AVAsset {
        guard let videoTrack = firstVideoTrack else {
            throw VideoTrimmingError.assetIsMissingVideoTrack
        }

        let trimmedTrack = try videoTrack.trimmingBlankFrames()

        guard let trimmedAsset = trimmedTrack.asset else {
            assertionFailure("Track is somehow missing asset")
            return AVMutableComposition()
        }

        return trimmedAsset
    }
}

extension AVAssetTrack {
    /**
     Returns the dimensions of the track if it's a video.
     */
    var dimensions: CGSize? {
        guard naturalSize != .zero else {
            return nil
        }

        let size = naturalSize.applying(preferredTransform)
        let preferredSize = CGSize(width: abs(size.width), height: abs(size.height))

        // Workaround for https://github.com/sindresorhus/Gifski/issues/76
        guard preferredSize != .zero else {
            return asset?.image(at: CMTime(seconds: 0, preferredTimescale: .video))?.size
        }

        return preferredSize
    }

    /**
     Returns the frame rate of the track if it's a video.
     */
    var frameRate: Double? { Double(nominalFrameRate) }

    /**
     Returns the aspect ratio of the track if it's a video.
     */
    var aspectRatio: Double? {
        guard let dimensions = dimensions else {
            return nil
        }

        return dimensions.height / dimensions.width
    }

    /**
     Example:
     `avc1` (video)
     `aac` (audio)
     */
    var codecIdentifier: String? {
        guard
            let rawDescription = formatDescriptions.first
        else {
            return nil
        }

        // This is the only way to do it. It's guaranteed to be this type.
        // swiftlint:disable:next force_cast
        let formatDescription = rawDescription as! CMFormatDescription

        return CMFormatDescriptionGetMediaSubType(formatDescription).fourCharCodeToString()
    }

    var codec: AVFormat? {
        guard let codecString = codecIdentifier else {
            return nil
        }

        return AVFormat(fourCC: codecString)
    }

    /**
     Use this for presenting the codec to the user. This is either the codec name, if known, or the codec identifier. You can just default to `"Unknown"` if this is `nil`.
     */
    var codecTitle: String? { codec?.description ?? codecIdentifier }

    /**
     Returns a debug string with the media format.

     Example: `vide/avc1`
     */
    var mediaFormat: String {
        // This is the only way to do it. It's guaranteed to be this type.
        // swiftlint:disable:next force_cast
        let descriptions = formatDescriptions as! [CMFormatDescription]

        var format = [String]()
        for description in descriptions {
            // Get string representation of media type (vide, soun, sbtl, etc.)
            let type = CMFormatDescriptionGetMediaType(description).fourCharCodeToString()

            // Get string representation media subtype (avc1, aac, tx3g, etc.)
            let subType = CMFormatDescriptionGetMediaSubType(description).fourCharCodeToString()

            format.append("\(type)/\(subType)")
        }

        return format.joined(separator: ",")
    }

    /**
     Estimated file size of the track in bytes.
     */
    var estimatedFileSize: Int {
        let dataRateInBytes = Double(estimatedDataRate / 8)
        return Int(timeRange.duration.seconds * dataRateInBytes)
    }
}

extension AVAssetTrack {
    /**
     Whether the track's duration is the same as the total asset duration.
     */
    var isFullDuration: Bool { timeRange.duration == asset?.duration }

    /**
     Extract the track into a new AVAsset.

     Optionally, mutate the track.

     This can be useful if you only want the video or audio of an asset. For example, sometimes the video track duration is shorter than the total asset duration. Extracting the track into a new asset ensures the asset duration is only as long as the video track duration.
     */
    func extractToNewAsset(
        _ modify: ((AVMutableCompositionTrack) -> Void)? = nil
    ) -> AVAsset? {
        let composition = AVMutableComposition()

        guard
            let track = composition.addMutableTrack(
                withMediaType: mediaType,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ),
            (try? track.insertTimeRange(
                CMTimeRange(start: .zero, duration: timeRange.duration),
                of: self,
                at: .zero
            )) != nil
        else {
            return nil
        }

        track.preferredTransform = preferredTransform

        modify?(track)

        return composition
    }
}

extension AVAssetTrack {
    struct VideoKeyframeInfo {
        let frameCount: Int
        let keyframeCount: Int

        var keyframeInterval: Double {
            Double(frameCount) / Double(keyframeCount)
        }

        var keyframeRate: Double {
            Double(keyframeCount) / Double(frameCount)
        }
    }

    func getKeyframeInfo() -> VideoKeyframeInfo? {
        guard
            let asset = asset,
            let reader = try? AVAssetReader(asset: asset)
        else {
            return nil
        }

        let trackReaderOutput = AVAssetReaderTrackOutput(track: self, outputSettings: nil)
        reader.add(trackReaderOutput)

        guard reader.startReading() else {
            return nil
        }

        var frameCount = 0
        var keyframeCount = 0

        while true {
            guard let sampleBuffer = trackReaderOutput.copyNextSampleBuffer() else {
                reader.cancelReading()
                break
            }

            if sampleBuffer.numSamples > 0 {
                frameCount += 1

                if sampleBuffer.sampleAttachments.first?[.notSync] == nil {
                    keyframeCount += 1
                }
            }
        }

        return VideoKeyframeInfo(frameCount: frameCount, keyframeCount: keyframeCount)
    }
}

/*
 > FOURCC is short for "four character code" - an identifier for a video codec, compression format, color or pixel format used in media files.
 */
extension FourCharCode {
    /**
     Create a String representation of a FourCC.
     */
    func fourCharCodeToString() -> String {
        let a_ = self >> 24
        let b_ = self >> 16
        let c_ = self >> 8
        let d_ = self

        let bytes: [CChar] = [
            CChar(a_ & 0xFF),
            CChar(b_ & 0xFF),
            CChar(c_ & 0xFF),
            CChar(d_ & 0xFF),
            0,
        ]

        // Swift type-checking is too slow for this...
        //		let bytes: [CChar] = [
        //			CChar((self >> 24) & 0xff),
        //			CChar((self >> 16) & 0xff),
        //			CChar((self >> 8) & 0xff),
        //			CChar(self & 0xff),
        //			0
        //		]

        return String(cString: bytes).trimmingCharacters(in: .whitespaces)
    }
}

enum AVFormat: String {
    case hevc
    case h264
    case av1
    case vp9
    case appleProResRAWHQ
    case appleProResRAW
    case appleProRes4444XQ
    case appleProRes4444
    case appleProRes422HQ
    case appleProRes422
    case appleProRes422LT
    case appleProRes422Proxy
    case appleAnimation

    // https://hap.video/using-hap.html
    // https://github.com/Vidvox/hap/blob/master/documentation/HapVideoDRAFT.md#names-and-identifiers
    case hap1
    case hap5
    case hapY
    case hapM
    case hapA
    case hap7

    case cineFormHD

    // https://en.wikipedia.org/wiki/QuickTime_Graphics
    case quickTimeGraphics

    // https://en.wikipedia.org/wiki/Avid_DNxHD
    case avidDNxHD

    init?(fourCC: String) {
        switch fourCC.trimmingCharacters(in: .whitespaces) {
        case "hvc1":
            self = .hevc
        case "avc1":
            self = .h264
        case "av01":
            self = .av1
        case "vp09":
            self = .vp9
        case "aprh":  // From https://avpres.net/Glossar/ProResRAW.html
            self = .appleProResRAWHQ
        case "aprn":
            self = .appleProResRAW
        case "ap4x":
            self = .appleProRes4444XQ
        case "ap4h":
            self = .appleProRes4444
        case "apch":
            self = .appleProRes422HQ
        case "apcn":
            self = .appleProRes422
        case "apcs":
            self = .appleProRes422LT
        case "apco":
            self = .appleProRes422Proxy
        case "rle":
            self = .appleAnimation
        case "Hap1":
            self = .hap1
        case "Hap5":
            self = .hap5
        case "HapY":
            self = .hapY
        case "HapM":
            self = .hapM
        case "HapA":
            self = .hapA
        case "Hap7":
            self = .hap7
        case "CFHD":
            self = .cineFormHD
        case "smc":
            self = .quickTimeGraphics
        case "AVdh":
            self = .avidDNxHD
        default:
            return nil
        }
    }

    init?(fourCC: FourCharCode) {
        self.init(fourCC: fourCC.fourCharCodeToString())
    }

    var fourCC: String {
        switch self {
        case .hevc:
            return "hvc1"
        case .h264:
            return "avc1"
        case .av1:
            return "av01"
        case .vp9:
            return "vp09"
        case .appleProResRAWHQ:
            return "aprh"
        case .appleProResRAW:
            return "aprn"
        case .appleProRes4444XQ:
            return "ap4x"
        case .appleProRes4444:
            return "ap4h"
        case .appleProRes422HQ:
            return "apcn"
        case .appleProRes422:
            return "apch"
        case .appleProRes422LT:
            return "apcs"
        case .appleProRes422Proxy:
            return "apco"
        case .appleAnimation:
            return "rle "
        case .hap1:
            return "Hap1"
        case .hap5:
            return "Hap5"
        case .hapY:
            return "HapY"
        case .hapM:
            return "HapM"
        case .hapA:
            return "HapA"
        case .hap7:
            return "Hap7"
        case .cineFormHD:
            return "CFHD"
        case .quickTimeGraphics:
            return "smc"
        case .avidDNxHD:
            return "AVdh"
        }
    }

    var isAppleProRes: Bool {
        [
            .appleProResRAWHQ,
            .appleProResRAW,
            .appleProRes4444XQ,
            .appleProRes4444,
            .appleProRes422HQ,
            .appleProRes422,
            .appleProRes422LT,
            .appleProRes422Proxy,
        ].contains(self)
    }

    /**
     - Important: This check only covers known (by us) compatible formats. It might be missing some. Don't use it for strict matching. Also keep in mind that even though a codec is supported, it might still not be decodable as the codec profile level might not be supported.
     */
    var isSupported: Bool {
        self == .hevc || self == .h264 || isAppleProRes
    }
}

extension AVFormat: CustomStringConvertible {
    var description: String {
        switch self {
        case .hevc:
            return "HEVC"
        case .h264:
            return "H264"
        case .av1:
            return "AV1"
        case .vp9:
            return "VP9"
        case .appleProResRAWHQ:
            return "Apple ProRes RAW HQ"
        case .appleProResRAW:
            return "Apple ProRes RAW"
        case .appleProRes4444XQ:
            return "Apple ProRes 4444 XQ"
        case .appleProRes4444:
            return "Apple ProRes 4444"
        case .appleProRes422HQ:
            return "Apple ProRes 422 HQ"
        case .appleProRes422:
            return "Apple ProRes 422"
        case .appleProRes422LT:
            return "Apple ProRes 422 LT"
        case .appleProRes422Proxy:
            return "Apple ProRes 422 Proxy"
        case .appleAnimation:
            return "Apple Animation"
        case .hap1:
            return "Vidvox Hap"
        case .hap5:
            return "Vidvox Hap Alpha"
        case .hapY:
            return "Vidvox Hap Q"
        case .hapM:
            return "Vidvox Hap Q Alpha"
        case .hapA:
            return "Vidvox Hap Alpha-Only"
        case .hap7:
            // No official name for this.
            return "Vidvox Hap"
        case .cineFormHD:
            return "CineForm HD"
        case .quickTimeGraphics:
            return "QuickTime Graphics"
        case .avidDNxHD:
            return "Avid DNxHD"
        }
    }
}

extension AVFormat: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(description) (\(fourCC.trimmingCharacters(in: .whitespaces)))"
    }
}

extension AVMediaType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .audio:
            return "Audio"
        case .closedCaption:
            return "Closed-caption content"
        case .depthData:
            return "Depth data"
        case .metadata:
            return "Metadata"
        #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
            case .metadataObject:
                return "Metadata objects"
        #endif
        case .muxed:
            return "Muxed media"
        case .subtitle:
            return "Subtitles"
        case .text:
            return "Text"
        case .timecode:
            return "Time code"
        case .video:
            return "Video"
        default:
            return "Unknown"
        }
    }
}

extension AVAsset {
    /**
     Whether the first video track is decodable.
     */
    var isVideoDecodable: Bool {
        guard
            isReadable,
            let firstVideoTrack = tracks(withMediaType: .video).first
        else {
            return false
        }

        return firstVideoTrack.isDecodable
    }

    /**
     Returns a boolean of whether there are any video tracks.
     */
    var hasVideo: Bool { !tracks(withMediaType: .video).isEmpty }

    /**
     Returns a boolean of whether there are any audio tracks.
     */
    var hasAudio: Bool { !tracks(withMediaType: .audio).isEmpty }

    /**
     Returns the first video track if any.
     */
    var firstVideoTrack: AVAssetTrack? { tracks(withMediaType: .video).first }

    /**
     Returns the first audio track if any.
     */
    var firstAudioTrack: AVAssetTrack? { tracks(withMediaType: .audio).first }

    /**
     Returns the dimensions of the first video track if any.
     */
    var dimensions: CGSize? { firstVideoTrack?.dimensions }

    /**
     Returns the frame rate of the first video track if any.
     */
    var frameRate: Double? { firstVideoTrack?.frameRate }

    /**
     Returns the aspect ratio of the first video track if any.
     */
    var aspectRatio: Double? { firstVideoTrack?.aspectRatio }

    /**
     Returns the video codec of the first video track if any.
     */
    var videoCodec: AVFormat? { firstVideoTrack?.codec }

    /**
     Returns the audio codec of the first audio track if any.

     Example: `aac`
     */
    var audioCodec: String? { firstAudioTrack?.codecIdentifier }

    /**
     The file size of the asset in bytes.

     - Note: If self is an `AVAsset` and not an `AVURLAsset`, the file size will just be an estimate.
     */
    var fileSize: Int {
        guard let urlAsset = self as? AVURLAsset else {
            return tracks.sum(\.estimatedFileSize)
        }

        return urlAsset.url.fileSize
    }

    var fileSizeFormatted: String { fileSize.bytesFormattedAsFileSize }
}

extension AVAsset {
    /**
     Returns debug info for the asset to use in logging and error messages.
     */
    var debugInfo: String {
        var output = [String]()

        let durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .abbreviated

        output.append(
            """
            ## AVAsset debug info ##
            Extension: \(describing: (self as? AVURLAsset)?.url.fileExtension)
            Video codec: \(videoCodec?.debugDescription ?? firstVideoTrack?.codecIdentifier ?? "nil")
            Audio codec: \(describing: audioCodec)
            Duration: \(describing: durationFormatter.stringSafe(from: duration.seconds))
            Dimension: \(describing: dimensions?.formatted)
            Frame rate: \(describing: frameRate?.rounded(toDecimalPlaces: 2).formatted)
            File size: \(fileSizeFormatted)
            Is readable: \(isReadable)
            Is playable: \(isPlayable)
            Is exportable: \(isExportable)
            Has protected content: \(hasProtectedContent)
            """
        )

        for track in tracks {
            output.append(
                """
                Track #\(track.trackID)
                ----
                Type: \(track.mediaType.debugDescription)
                Codec: \(describing: track.mediaType == .video ? (track.codec?.debugDescription ?? track.codecIdentifier) : track.codecIdentifier)
                Duration: \(describing: durationFormatter.stringSafe(from: track.timeRange.duration.seconds))
                Dimensions: \(describing: track.dimensions?.formatted)
                Natural size: \(describing: track.naturalSize)
                Frame rate: \(describing: track.frameRate?.rounded(toDecimalPlaces: 2).formatted)
                Is playable: \(track.isPlayable)
                Is decodable: \(track.isDecodable)
                ----
                """
            )
        }

        return output.joined(separator: "\n\n")
    }
}

extension AVAsset {
    struct VideoMetadata {
        let dimensions: CGSize
        let duration: Double
        let frameRate: Double
        let fileSize: Int
    }

    var videoMetadata: VideoMetadata? {
        guard
            let dimensions = dimensions,
            let frameRate = frameRate
        else {
            return nil
        }

        return VideoMetadata(
            dimensions: dimensions,
            duration: duration.seconds,
            frameRate: frameRate,
            fileSize: fileSize
        )
    }
}

extension URL {
    var videoMetadata: AVAsset.VideoMetadata? { AVURLAsset(url: self).videoMetadata }

    var isVideoDecodable: Bool { AVAsset(url: self).isVideoDecodable }
}

typealias QueryDictionary = [String: String]

extension CharacterSet {
    /**
     Characters allowed to be unescaped in an URL.

     https://tools.ietf.org/html/rfc3986#section-2.3
     */
    static let urlUnreservedRFC3986 = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
    )
}

/// This should really not be necessary, but it's at least needed for my `formspree.io` form...
///
/// Otherwise is results in "Internal Server Error" after submitting the form.
///
/// Relevant: https://www.djackson.org/why-we-do-not-use-urlcomponents/
private func escapeQueryComponent(_ query: String) -> String {
    query.addingPercentEncoding(withAllowedCharacters: .urlUnreservedRFC3986)!
}

extension Dictionary where Key == String {
    /**
     This correctly escapes items. See `escapeQueryComponent`.
     */
    var toQueryItems: [URLQueryItem] {
        map {
            URLQueryItem(
                name: escapeQueryComponent($0),
                value: escapeQueryComponent("\($1)")
            )
        }
    }

    var toQueryString: String {
        var components = URLComponents()
        components.queryItems = toQueryItems
        return components.query!
    }
}

extension Dictionary {
    func compactValues<T>() -> [Key: T] where Value == T? {
        compactMapValues { $0 }
    }
}

extension URLComponents {
    /**
     This correctly escapes items. See `escapeQueryComponent`.
     */
    init?(string: String, query: QueryDictionary) {
        self.init(string: string)
        self.queryDictionary = query
    }

    /**
     This correctly escapes items. See `escapeQueryComponent`.
     */
    var queryDictionary: QueryDictionary {
        get {
            queryItems?.toDictionary { ($0.name, $0.value) }.compactValues() ?? [:]
        }
        set {
            // Using `percentEncodedQueryItems` instead of `queryItems` since the query items are already custom-escaped. See `escapeQueryComponent`.
            percentEncodedQueryItems = newValue.toQueryItems
        }
    }
}

extension URL {
    var directoryURL: Self { deletingLastPathComponent() }

    var directory: String { directoryURL.path }

    var filename: String {
        get { lastPathComponent }
        set {
            deleteLastPathComponent()
            appendPathComponent(newValue)
        }
    }

    var fileExtension: String {
        get { pathExtension }
        set {
            deletePathExtension()
            appendPathExtension(newValue)
        }
    }

    var filenameWithoutExtension: String {
        get { deletingPathExtension().lastPathComponent }
        set {
            let fileExtension = pathExtension
            deleteLastPathComponent()
            appendPathComponent(newValue)
            appendPathExtension(fileExtension)
        }
    }

    func changingFileExtension(to fileExtension: String) -> Self {
        var url = self
        url.fileExtension = fileExtension
        return url
    }

    /**
     Returns `self` with the given query dictionary merged in.

     The keys in the given dictionary overwrites any existing keys.
     */
    func settingQueryItems(from queryDictionary: QueryDictionary) -> Self {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        components.queryDictionary = components.queryDictionary.appending(queryDictionary)

        return components.url ?? self
    }

    private func resourceValue<T>(forKey key: URLResourceKey) -> T? {
        guard let values = try? resourceValues(forKeys: [key]) else {
            return nil
        }

        return values.allValues[key] as? T
    }

    private func boolResourceValue(forKey key: URLResourceKey, defaultValue: Bool = false) -> Bool {
        guard let values = try? resourceValues(forKeys: [key]) else {
            return defaultValue
        }

        return values.allValues[key] as? Bool ?? defaultValue
    }

    //	var contentType: UTType? { resourceValue(forKey: .contentTypeKey) }

    var typeIdentifier: String? { resourceValue(forKey: .typeIdentifierKey) }

    /**
     File size in bytes.
     */
    var fileSize: Int { resourceValue(forKey: .fileSizeKey) ?? 0 }

    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }

    // TODO: Use the below instead when targeting macOS 10.15. Also in `AVAsset#fileSize`.
    /**
     File size in bytes.
     */
    //	var fileSize: Measurement<UnitInformationStorage> { Measurement<UnitInformationStorage>(value: resourceValue(forKey: .fileSizeKey) ?? 0, unit: .bytes) }
    //
    //	var fileSizeFormatted: String {
    //		ByteCountFormatter.string(from: fileSize, countStyle: .file)
    //	}

    var exists: Bool { FileManager.default.fileExists(atPath: path) }

    var isReadable: Bool { boolResourceValue(forKey: .isReadableKey) }

    var isWritable: Bool { boolResourceValue(forKey: .isWritableKey) }

    var isVolumeReadonly: Bool { boolResourceValue(forKey: .volumeIsReadOnlyKey) }
}

extension CGSize {
    static func * (lhs: Self, rhs: Double) -> Self {
        .init(width: lhs.width * rhs, height: lhs.height * rhs)
    }

    init(widthHeight: Double) {
        self.init(width: widthHeight, height: widthHeight)
    }

    var cgRect: CGRect { .init(origin: .zero, size: self) }

    var longestSide: Double { max(width, height) }

    func aspectFit(to boundingSize: CGSize) -> Self {
        let ratio = min(boundingSize.width / width, boundingSize.height / height)
        return self * ratio
    }

    func aspectFit(to widthHeight: Double) -> Self {
        aspectFit(to: Self(width: widthHeight, height: widthHeight))
    }
}

extension CGRect {
    init(origin: CGPoint = .zero, width: Double, height: Double) {
        self.init(origin: origin, size: CGSize(width: width, height: height))
    }

    init(widthHeight: Double) {
        self.init()
        self.origin = .zero
        self.size = CGSize(widthHeight: widthHeight)
    }

    var x: Double {
        get { origin.x }
        set {
            origin.x = newValue
        }
    }

    var y: Double {
        get { origin.y }
        set {
            origin.y = newValue
        }
    }

    var width: Double {
        get { size.width }
        set {
            size.width = newValue
        }
    }

    var height: Double {
        get { size.height }
        set {
            size.height = newValue
        }
    }

    // MARK: - Edges

    var left: Double {
        get { x }
        set {
            x = newValue
        }
    }

    var right: Double {
        get { x + width }
        set {
            x = newValue - width
        }
    }

    var top: Double {
        get { y + height }
        set {
            y = newValue - height
        }
    }

    var bottom: Double {
        get { y }
        set {
            y = newValue
        }
    }

    // MARK: -

    var center: CGPoint {
        get { CGPoint(x: midX, y: midY) }
        set {
            origin = CGPoint(
                x: newValue.x - (size.width / 2),
                y: newValue.y - (size.height / 2)
            )
        }
    }

    var centerX: Double {
        get { midX }
        set {
            center = CGPoint(x: newValue, y: midY)
        }
    }

    var centerY: Double {
        get { midY }
        set {
            center = CGPoint(x: midX, y: newValue)
        }
    }

    /**
     Returns a `CGRect` where `self` is centered in `rect`.
     */
    func centered(
        in rect: Self,
        xOffset: Double = 0,
        yOffset: Double = 0
    ) -> Self {
        .init(
            x: ((rect.width - size.width) / 2) + xOffset,
            y: ((rect.height - size.height) / 2) + yOffset,
            width: size.width,
            height: size.height
        )
    }

    /**
     Returns a CGRect where `self` is centered in `rect`.

     - Parameters:
     	- xOffsetPercent: The offset in percentage of `rect.width`.
     */
    func centered(
        in rect: Self,
        xOffsetPercent: Double,
        yOffsetPercent: Double
    ) -> Self {
        centered(
            in: rect,
            xOffset: rect.width * xOffsetPercent,
            yOffset: rect.height * yOffsetPercent
        )
    }
}

// swiftlint:disable:next no_cgfloat
extension CGFloat {
    var double: Double { Double(self) }
}

extension Error {
    var isNsError: Bool { Self.self is NSError.Type }
}

extension NSError {
    static func from(error: Error, userInfo: [String: Any] = [:]) -> NSError {
        let nsError = error as NSError

        // Since Error and NSError are often bridged between each other, we check if it was originally an NSError and then return that.
        guard !error.isNsError else {
            guard !userInfo.isEmpty else {
                return nsError
            }

            return nsError.appending(userInfo: userInfo)
        }

        var userInfo = userInfo
        userInfo[NSLocalizedDescriptionKey] = error.localizedDescription

        // This is needed as `localizedDescription` often lacks important information, for example, when an NSError is wrapped in a Swift.Error.
        userInfo["Swift.Error"] = "\(nsError.domain).\(error)"

        // Awful, but no better way to get the enum case name.
        // This gets `Error.generateFrameFailed` from `Error.generateFrameFailed(Error Domain=AVFoundationErrorDomain Code=-11832 […]`.
        let errorName = "\(error)".split(separator: "(").first ?? ""

        return .init(
            //			domain: "\(SSApp.id) - \(nsError.domain)\(errorName.isEmpty ? "" : ".")\(errorName)",
            domain: "APP - \(nsError.domain)\(errorName.isEmpty ? "" : ".")\(errorName)",
            code: nsError.code,
            userInfo: userInfo
        )
    }

    /**
     Returns a new error with the user info appended.
     */
    func appending(userInfo newUserInfo: [String: Any]) -> Self {
        .init(
            domain: domain,
            code: code,
            userInfo: userInfo.appending(newUserInfo)
        )
    }
}

extension NSError {
    /**
     Use this for generic app errors.

     - Note: Prefer using a specific enum-type error whenever possible.

     - Parameter description: The description of the error. This is shown as the first line in error dialogs.
     - Parameter recoverySuggestion: Explain how the user how they can recover from the error. For example, "Try choosing a different directory". This is usually shown as the second line in error dialogs.
     - Parameter userInfo: Metadata to add to the error. Can be a custom key or any of the `NSLocalizedDescriptionKey` keys except `NSLocalizedDescriptionKey` and `NSLocalizedRecoverySuggestionErrorKey`.
     - Parameter domainPostfix: String to append to the `domain` to make it easier to identify the error. The domain is the app's bundle identifier.
     */
    static func appError(
        _ description: String,
        recoverySuggestion: String? = nil,
        userInfo: [String: Any] = [:],
        domainPostfix: String? = nil
    ) -> Self {
        var userInfo = userInfo
        userInfo[NSLocalizedDescriptionKey] = description

        if let recoverySuggestion = recoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion
        }

        return .init(
            //			domain: domainPostfix.map { "\(SSApp.id) - \($0)" } ?? SSApp.id,
            domain: domainPostfix.map { "APP - \($0)" } ?? "APP",
            code: 1,  // This is what Swift errors end up as.
            userInfo: userInfo
        )
    }
}

extension Dictionary {
    /**
     Adds the elements of the given dictionary to a copy of self and returns that.

     Identical keys in the given dictionary overwrites keys in the copy of self.
     */
    func appending(_ dictionary: [Key: Value]) -> [Key: Value] {
        var newDictionary = self

        for (key, value) in dictionary {
            newDictionary[key] = value
        }

        return newDictionary
    }
}

enum FileType {
    case png
    case jpeg
    case heic
    case tiff
    case gif

    static func from(fileExtension: String) -> Self {
        switch fileExtension {
        case "png":
            return .png
        case "jpg", "jpeg":
            return .jpeg
        case "heic":
            return .heic
        case "tif", "tiff":
            return .tiff
        case "gif":
            return .gif
        default:
            fatalError("Unsupported file type")
        }
    }

    static func from(url: URL) -> Self {
        from(fileExtension: url.pathExtension)
    }

    var name: String {
        switch self {
        case .png:
            return "PNG"
        case .jpeg:
            return "JPEG"
        case .heic:
            return "HEIC"
        case .tiff:
            return "TIFF"
        case .gif:
            return "GIF"
        }
    }

    var identifier: String {
        switch self {
        case .png:
            return "public.png"
        case .jpeg:
            return "public.jpeg"
        case .heic:
            return "public.heic"
        case .tiff:
            return "public.tiff"
        case .gif:
            return "com.compuserve.gif"
        }
    }

    var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        case .heic:
            return "heic"
        case .tiff:
            return "tiff"
        case .gif:
            return "gif"
        }
    }
}

extension Sequence {
    /**
     Returns the sum of elements in a sequence by mapping the elements with a numerator.

     ```
     [1, 2, 3].sum { $0 == 1 ? 10 : $0 }
     //=> 15
     ```
     */
    func sum<T: AdditiveArithmetic>(_ numerator: (Element) throws -> T) rethrows -> T {
        var result = T.zero

        for element in self {
            result += try numerator(element)
        }

        return result
    }
}

extension Sequence {
    /**
     Convert a sequence to a dictionary by mapping over the values and using the returned key as the key and the current sequence element as value.

     ```
     [1, 2, 3].toDictionary { $0 }
     //=> [1: 1, 2: 2, 3: 3]
     ```
     */
    func toDictionary<Key: Hashable>(with pickKey: (Element) -> Key) -> [Key: Element] {
        var dictionary = [Key: Element]()
        for element in self {
            dictionary[pickKey(element)] = element
        }
        return dictionary
    }

    /**
     Convert a sequence to a dictionary by mapping over the elements and returning a key/value tuple representing the new dictionary element.

     ```
     [(1, "a"), (2, "b")].toDictionary { ($1, $0) }
     //=> ["a": 1, "b": 2]
     ```
     */
    func toDictionary<Key: Hashable, Value>(with pickKeyValue: (Element) -> (Key, Value)) -> [Key:
        Value]
    {
        var dictionary = [Key: Value]()
        for element in self {
            let newElement = pickKeyValue(element)
            dictionary[newElement.0] = newElement.1
        }
        return dictionary
    }

    /**
     Same as the above but supports returning optional values.

     ```
     [(1, "a"), (nil, "b")].toDictionary { ($1, $0) }
     //=> ["a": 1, "b": nil]
     ```
     */
    func toDictionary<Key: Hashable, Value>(with pickKeyValue: (Element) -> (Key, Value?)) -> [Key:
        Value?]
    {
        var dictionary = [Key: Value?]()
        for element in self {
            let newElement = pickKeyValue(element)
            dictionary[newElement.0] = newElement.1
        }
        return dictionary
    }
}

extension BinaryFloatingPoint {
    func rounded(
        toDecimalPlaces decimalPlaces: Int,
        rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> Self {
        guard decimalPlaces >= 0 else {
            return self
        }

        var divisor: Self = 1
        for _ in 0..<decimalPlaces { divisor *= 10 }

        return (self * divisor).rounded(rule) / divisor
    }
}

extension CGSize {
    func rounded(_ rule: FloatingPointRoundingRule = .toNearestOrAwayFromZero) -> Self {
        Self(width: width.rounded(rule), height: height.rounded(rule))
    }
}

extension Collection {
    /**
     Returns the element at the specified index if it is within bounds, otherwise `nil`.
     */
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension URL {
    var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: true)
    }

    var queryDictionary: [String: String] { components?.queryDictionary ?? [:] }
}

extension CMTimeRange {
    /**
     Get `self` as a range in seconds.

     Can be `nil` when the range is not available, for example, when an asset has not yet been fully loaded or if it's a live stream.
     */
    var range: ClosedRange<Double>? {
        guard
            start.isNumeric,
            end.isNumeric
        else {
            return nil
        }

        return start.seconds...end.seconds
    }
}

extension ClosedRange where Bound: AdditiveArithmetic {
    /**
     Get the length between the lower and upper bound.
     */
    var length: Bound { upperBound - lowerBound }
}

extension ClosedRange {
    /**
     Returns true if `self` is a superset of the given range.

     ```
     (1.0...1.5).isSuperset(of: 1.2...1.3)
     //=> true
     ```
     */
    func isSuperset(of other: Self) -> Bool {
        other.isEmpty || (lowerBound <= other.lowerBound && other.upperBound <= upperBound)
    }

    /**
     Returns true if `self` is a subset of the given range.

     ```
     (1.2...1.3).isSubset(of: 1.0...1.5)
     //=> true
     ```
     */
    func isSubset(of other: Self) -> Bool {
        other.isSuperset(of: self)
    }
}

extension ClosedRange where Bound == Double {
    // TODO: Add support for negative ranges.
    /**
     Make a new range where the length (difference between the lower and upper bound) is at least the given amount.

     The use-case for this method is being able to ensure a sub-range inside a range is of a certain size.

     It will first try to expand on both the lower and upper bound, and if not possible, it will expand the lower bound, and if that is not possible, it will expand the upper bound. If the resulting range is larger than the given `fullRange`, it will be clamped to `fullRange`.

     - Precondition: The range and the given range must be positive.
     - Precondition: The range must be a subset of the given range.

     ```
     (1...1.2).minimumRangeLength(of: 1, in: 0...4)
     //=> 0.5...1.7

     (0...0.5).minimumRangeLength(of: 1, in: 0...4)
     //=> 0...1

     (3.5...4).minimumRangeLength(of: 1, in: 0...4)
     //=> 3...4

     (0...0.1).minimumRangeLength(of: 1, in: 0...4)
     //=> 0...1
     ```
     */
    func minimumRangeLength(of length: Bound, in fullRange: Self) -> Self {
        guard length > self.length else {
            return self
        }

        assert(isSubset(of: fullRange), "`self` must be a subset of the given range")
        assert(lowerBound >= 0 && upperBound >= 0, "`self` must the positive")
        assert(
            fullRange.lowerBound >= 0 && fullRange.upperBound >= 0,
            "The given range must be positive"
        )

        let lower = lowerBound - (length / 2)
        let upper = upperBound + (length / 2)

        if fullRange.contains(lower),
            fullRange.contains(upper)
        {
            return lower...upper
        }

        if !fullRange.contains(lower),
            fullRange.contains(upper)
        {
            return fullRange.lowerBound...length
        }

        if fullRange.contains(lower),
            !fullRange.contains(upper)
        {
            return (fullRange.upperBound - length)...fullRange.upperBound
        }

        return self
    }
}

extension DateComponentsFormatter {
    /**
     Like `string(from: TimeInterval)` but does not cause an `NSInternalInconsistencyException` exception for `NaN` and `Infinity`.

     This is especially useful when formatting `CMTime#seconds` which can often be `NaN`.
     */
    func stringSafe(from timeInterval: TimeInterval) -> String? {
        guard !timeInterval.isNaN else {
            return "NaN"
        }

        guard timeInterval.isFinite else {
            return "Infinity"
        }

        return string(from: timeInterval)
    }
}

extension Sequence {
    /**
     Returns an array of elements split into groups of the given size.

     If it can't be split evenly, the final chunk will be the remaining elements.

     If the requested chunk size is larger than the sequence, the chunk will be smaller than requested.

     ```
     [1, 2, 3, 4].chunked(by: 2)
     //=> [[1, 2], [3, 4]]
     ```
     */
    func chunked(by chunkSize: Int) -> [[Element]] {
        reduce(into: []) { result, current in
            if let last = result.last, last.count < chunkSize {
                result.append(result.removeLast() + [current])
            } else {
                result.append([current])
            }
        }
    }
}

extension Collection where Index == Int {
    /**
     Return a subset of the array of the given length by sampling "evenly distributed" elements.
     */
    func sample(length: Int) -> [Element] {
        precondition(length >= 0, "The length cannot be negative.")

        guard length < count else {
            return Array(self)
        }

        return (0..<length).map { self[($0 * count + count / 2) / length] }
    }
}

extension Sequence where Element: Sequence {
    func flatten() -> [Element.Element] {
        flatMap { $0 }
    }
}

extension UnsafeMutableRawPointer {
    /**
     Convert an unsafe mutable raw pointer to an array.

     ```
     let bytes = sourceBuffer.data?.toArray(to: UInt8.self, capacity: Int(sourceBuffer.height) * sourceBuffer.rowBytes)
     ```
     */
    func toArray<T>(to type: T.Type, capacity count: Int) -> [T] {
        let pointer = bindMemory(to: type, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}

extension Data {
    /**
     The bytes of the data.
     */
    var bytes: [UInt8] { [UInt8](self) }
}

extension Array where Element == UInt8 {
    /**
     Convert the array to data.
     */
    var data: Data { Data(self) }
}

extension CGImage {
    static let empty = NSImage(size: CGSize(widthHeight: 1), flipped: false) { _ in true }
        .cgImage(forProposedRect: nil, context: nil, hints: nil)!
}

extension CGImage {
    var size: CGSize { CGSize(width: width, height: height) }

    var hasAlphaChannel: Bool {
        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast:
            return true
        default:
            return false
        }
    }
}

extension CGImage {
    /**
     A read-only pointer to the bytes of the image.

     - Important: Don't assume the format of the underlaying storage. It could be `ARGB`, but it could also be `RGBA`. Draw the image into a `CGContext` first to be safe. See `CGImage#converting`.
     */
    var bytePointer: UnsafePointer<UInt8>? {
        guard let data = dataProvider?.data else {
            return nil
        }

        return CFDataGetBytePtr(data)
    }

    /**
     The bytes of the image.

     - Important: Don't assume the format of the underlaying storage. It could be `ARGB`, but it could also be `RGBA`. Draw the image into a `CGContext` first to be safe. See `CGImage#converting`.
     */
    var bytes: [UInt8]? {  // swiftlint:disable:this discouraged_optional_collection
        guard let data = dataProvider?.data else {
            return nil
        }

        return (data as Data).bytes
    }
}

extension CGContext {
    /**
     Create a premultiplied RGB bitmap context.

     - Note: `CGContext` does not support non-premultiplied RGB.
     */
    static func rgbBitmapContext(
        pixelFormat: CGImage.PixelFormat,
        width: Int,
        height: Int,
        withAlpha: Bool
    ) -> CGContext? {
        let byteOrder: CGBitmapInfo
        let alphaInfo: CGImageAlphaInfo
        switch pixelFormat {
        case .argb:
            byteOrder = .byteOrder32Big
            alphaInfo = withAlpha ? .premultipliedFirst : .noneSkipFirst
        case .rgba:
            byteOrder = .byteOrder32Big
            alphaInfo = withAlpha ? .premultipliedLast : .noneSkipLast
        case .bgra:
            byteOrder = .byteOrder32Little
            alphaInfo = withAlpha ? .premultipliedFirst : .noneSkipFirst  // This might look wrong, but the order is inverse because of little endian.
        case .abgr:
            byteOrder = .byteOrder32Little
            alphaInfo = withAlpha ? .premultipliedLast : .noneSkipLast
        }

        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: byteOrder.rawValue | alphaInfo.rawValue
        )
    }
}

extension vImage_Buffer {
    /**
     The bytes of the image.
     */
    var bytes: [UInt8] {
        data?.toArray(to: UInt8.self, capacity: rowBytes * Int(height)) ?? []
    }
}

extension CGImage {
    /**
     Convert an image to a `vImage` buffer of the given pixel format.

     - Parameter premultiplyAlpha: Whether the alpha channel should be premultiplied.
     */
    @available(macOS 11, *)
    func toVImageBuffer(
        pixelFormat: PixelFormat,
        premultiplyAlpha: Bool
    ) throws -> vImage_Buffer {
        guard let sourceFormat = vImage_CGImageFormat(cgImage: self) else {
            throw NSError.appError("Could not initialize vImage_CGImageFormat")
        }

        let alphaFirst = premultiplyAlpha ? CGImageAlphaInfo.premultipliedFirst : .first
        let alphaLast = premultiplyAlpha ? CGImageAlphaInfo.premultipliedLast : .last

        let byteOrder: CGBitmapInfo
        let alphaInfo: CGImageAlphaInfo
        switch pixelFormat {
        case .argb:
            byteOrder = .byteOrder32Big
            alphaInfo = alphaFirst
        case .rgba:
            byteOrder = .byteOrder32Big
            alphaInfo = alphaLast
        case .bgra:
            byteOrder = .byteOrder32Little
            alphaInfo = alphaFirst  // This might look wrong, but the order is inverse because of little endian.
        case .abgr:
            byteOrder = .byteOrder32Little
            alphaInfo = alphaLast
        }

        guard
            let destinationFormat = vImage_CGImageFormat(
                bitsPerComponent: 8,
                bitsPerPixel: 8 * 4,
                colorSpace: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: byteOrder.rawValue | alphaInfo.rawValue),
                renderingIntent: .defaultIntent
            )
        else {
            // TODO: Use a proper error.
            throw NSError.appError("Could not initialize vImage_CGImageFormat")
        }

        let converter = try vImageConverter.make(
            sourceFormat: sourceFormat,
            destinationFormat: destinationFormat
        )

        let sourceBuffer = try vImage_Buffer(cgImage: self, format: sourceFormat)

        defer {
            sourceBuffer.free()
        }

        var destinationBuffer = try vImage_Buffer(
            size: sourceBuffer.size,
            bitsPerPixel: destinationFormat.bitsPerPixel
        )

        try converter.convert(source: sourceBuffer, destination: &destinationBuffer)

        return destinationBuffer
    }
}

extension CGImage {
    /**
     Convert the image to use the given underlying pixel format.

     Prefer `CGImage#pixels(…)` if you need to read the pixels of an image. It's faster and also suppot non-premultiplied alpha.

     - Note: The byte pointer uses premultiplied alpha.

     ```
     let image = result.image.converting(to: .argb)
     let bytePointer = image.bytePointer
     let bytesPerRow = image.bytesPerRow
     ```
     */
    func converting(to pixelFormat: PixelFormat) -> CGImage? {
        guard
            let context = CGContext.rgbBitmapContext(
                pixelFormat: pixelFormat,
                width: width,
                height: height,
                withAlpha: hasAlphaChannel
            )
        else {
            return nil
        }

        context.draw(self, in: CGRect(origin: .zero, size: size))

        return context.makeImage()
    }
}

extension CGImage {
    enum PixelFormat {
        /**
         Big-endian, alpha first.
         */
        case argb

        /**
         Big-endian, alpha last.
         */
        case rgba

        /**
         Little-endian, alpha first.
         */
        case bgra

        /**
         Little-endian, alpha last.
         */
        case abgr

        var title: String {
            switch self {
            case .argb:
                return "ARGB"
            case .rgba:
                return "RGBA"
            case .bgra:
                return "BGRA"
            case .abgr:
                return "ABGR"
            }
        }
    }
}

extension CGImage.PixelFormat: CustomDebugStringConvertible {
    var debugDescription: String { "CGImage.PixelFormat(\(title)" }
}

extension CGImage {
    struct Pixels {
        let bytes: [UInt8]
        let width: Int
        let height: Int
        let bytesPerRow: Int
    }

    /**
     Get the pixels of an image.

     - Parameter premultiplyAlpha: Whether the alpha channel should be premultiplied.

     If you pass the pixels to a C API or external library, you most likely want `premultiplyAlpha: false`.
     */
    func pixels(
        as pixelFormat: PixelFormat,
        premultiplyAlpha: Bool
    ) throws -> Pixels {
        // For macOS 10.15 and older, we don't handle the `premultiplyAlpha` option as it never correctly worked before and I'm too lazy to fix it there.
        guard #available(macOS 11, *) else {
            guard
                let image = converting(to: pixelFormat),
                let bytes = image.bytes
            else {
                throw NSError.appError("Could not get the pixels of the image.")
            }

            return Pixels(
                bytes: bytes,
                width: image.width,
                height: image.height,
                bytesPerRow: image.bytesPerRow
            )
        }

        let buffer = try toVImageBuffer(
            pixelFormat: pixelFormat,
            premultiplyAlpha: premultiplyAlpha
        )

        defer {
            buffer.free()
        }

        return Pixels(
            bytes: buffer.bytes,
            width: Int(buffer.width),
            height: Int(buffer.height),
            bytesPerRow: buffer.rowBytes
        )
    }
}

extension CGBitmapInfo {
    /**
     The alpha info of the current `CGBitmapInfo`.
     */
    var alphaInfo: CGImageAlphaInfo {
        get {
            CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) ?? .none
        }
        set {
            remove(.alphaInfoMask)
            insert(.init(rawValue: newValue.rawValue))
        }
    }

    /**
     The pixel format of the image.

     Returns `nil` if the pixel format is not supported, for example, non-alpha.
     */
    var pixelFormat: CGImage.PixelFormat? {
        // While the host byte order is little-endian, by default, `CGImage` is stored in big-endian format on Intel Macs and little-endian on Apple silicon Macs.

        let alphaInfo = alphaInfo
        let isLittleEndian = contains(.byteOrder32Little)

        guard alphaInfo != .none else {
            // TODO: Support non-alpha formats.
            // return isLittleEndian ? .bgr : .rgb
            return nil
        }

        let isAlphaFirst =
            alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

        if isLittleEndian {
            return isAlphaFirst ? .bgra : .abgr
        } else {
            return isAlphaFirst ? .argb : .rgba
        }
    }

    /**
     Whether the alpha channel is premultipled.
     */
    var isPremultipliedAlpha: Bool {
        let alphaInfo = alphaInfo
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension CGColorSpace {
    /**
     Presentable title of the color space.
     */
    var title: String {
        guard let name = name else {
            return "Unknown"
        }

        return (name as String).replacingOccurrences(
            of: #"^kCGColorSpace"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
}

extension CGImage {
    /**
     Debug info for the image.

     ```
     print(image.debugInfo)
     ```
     */
    var debugInfo: String {
        """
        ## CGImage debug info ##
        Dimension: \(size.formatted)
        Pixel format: \(bitmapInfo.pixelFormat?.title, default: "Unknown")
        Premultiplied alpha: \(bitmapInfo.isPremultipliedAlpha)
        Color space: \(colorSpace?.title, default: "nil")
        """
    }
}

@propertyWrapper
struct Clamping<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.value = wrappedValue.clamped(to: range)
        self.range = range
    }

    var wrappedValue: Value {
        get { value }
        set {
            value = newValue.clamped(to: range)
        }
    }
}

extension CMTime {
    static func * (lhs: Self, rhs: Double) -> Self {
        CMTimeMultiplyByFloat64(lhs, multiplier: rhs)
    }

    static func *= (lhs: inout Self, rhs: Double) {
        // swiftlint:disable:next shorthand_operator
        lhs = lhs * rhs
    }

    static func / (lhs: Self, rhs: Double) -> Self {
        lhs * (1.0 / rhs)
    }

    static func /= (lhs: inout Self, rhs: Double) {
        // swiftlint:disable:next shorthand_operator
        lhs = lhs / rhs
    }
}

extension AVMutableCompositionTrack {
    /**
     Change the speed of the track using the given multiplier.

     1 is the current speed. 2 means doubled speed. Etc.
     */
    func changeSpeed(by speedMultiplier: Double) {
        scaleTimeRange(timeRange, toDuration: timeRange.duration / speedMultiplier)
    }
}

extension AVAssetTrack {
    /**
     Extract the track to a new asset and also change the speed of the track using the given multiplier.

     1 is the current speed. 2 means doubled speed. Etc.
     */
    func extractToNewAssetAndChangeSpeed(to speedMultiplier: Double) -> AVAsset? {
        extractToNewAsset {
            $0.changeSpeed(by: speedMultiplier)
        }
    }
}

extension NumberFormatter {
    func string<Value: Numeric>(from number: Value) -> String? {
        // swiftlint:disable:next legacy_objc_type
        guard let nsNumber = number as? NSNumber else {
            return nil
        }

        return string(from: nsNumber)
    }
}

extension FloatingPoint {
    /**
     Get the fraction component of a floating point number.

     ```
     let number = 1.22

     print(number.fractionComponent)
     //=> 0.22
     ```
     */
    var fractionComponent: Self { truncatingRemainder(dividingBy: 1) }
}

extension DateComponentsFormatter {
    /**
     Format a duration using a positional style and with fractional seconds.

     ```
     "00:12,45"
     ```

     This utiliity is needed since `formatter.allowsFractionalUnits = true` doesn't work. (macOS 11.6)
     https://openradar.appspot.com/32024200
     */
    static func localizedStringPositionalWithFractionalSeconds(
        _ duration: Double,
        minimumFractionDigits: Int = 2,
        maximumFractionDigits: Int = 2,
        includeHours: Bool = false,
        locale: Locale = .current
    ) -> String {
        var calendar = Calendar.current
        calendar.locale = locale

        let durationFormatter = self.init()
        durationFormatter.calendar = calendar
        durationFormatter.formattingContext = .standalone
        durationFormatter.unitsStyle = .positional
        durationFormatter.allowedUnits =
            includeHours ? [.hour, .minute, .second] : [.minute, .second]
        durationFormatter.zeroFormattingBehavior = .pad

        let fractionFormatter = NumberFormatter()
        fractionFormatter.locale = locale
        fractionFormatter.maximumIntegerDigits = 0
        fractionFormatter.minimumFractionDigits = minimumFractionDigits
        fractionFormatter.maximumFractionDigits = maximumFractionDigits
        fractionFormatter.alwaysShowsDecimalSeparator = false

        return durationFormatter.string(from: duration)! + fractionFormatter.string(
            from: duration.fractionComponent
        )!
    }
}
