//
//  AVAssetTrack.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation

extension AVAssetTrack {
    /// Returns the dimensions of the track if it's a video.
    var dimensions: CGSize? {
        guard naturalSize != .zero else {
            return nil
        }
        
        let size = naturalSize.applying(preferredTransform)
        let preferredSize = CGSize(width: abs(size.width), height: abs(size.height))
        
        // Workaround for https://github.com/sindresorhus/Gifski/issues/76
        guard preferredSize != .zero else {
            return asset?
                .image(at: CMTime(seconds: 0, preferredTimescale: .video))?
                .size
        }
        
        return preferredSize
    }
    
    /// Returns the frame rate of the track if it's a video.
    var frameRate: Double? { Double(nominalFrameRate) }
    
    /// Returns the aspect ratio of the track if it's a video.
    var aspectRatio: Double? {
        guard let dimensions = dimensions else {
            return nil
        }
        
        return dimensions.height / dimensions.width
    }
    
    /// Example:
    /// `avc1` (video)
    /// `aac` (audio)
    var codecIdentifier: String? {
        guard let rawDescription = formatDescriptions.first
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
    
    /// Use this for presenting the codec to the user. This is either the codec name, if known, or
    /// the codec identifier. You can just default to `"Unknown"` if this is `nil`.
    var codecTitle: String? { codec?.description ?? codecIdentifier }
    
    /// Returns a debug string with the media format.
    ///
    /// Example: `vide/avc1`
    var mediaFormat: String {
        // This is the only way to do it. It's guaranteed to be this type.
        // swiftlint:disable:next force_cast
        let descriptions = formatDescriptions as! [CMFormatDescription]
        
        var format = [String]()
        for description in descriptions {
            // Get string representation of media type (vide, soun, sbtl, etc.)
            let type = CMFormatDescriptionGetMediaType(description)
                .fourCharCodeToString()
            
            // Get string representation media subtype (avc1, aac, tx3g, etc.)
            let subType = CMFormatDescriptionGetMediaSubType(description)
                .fourCharCodeToString()
            
            format.append("\(type)/\(subType)")
        }
        
        return format.joined(separator: ",")
    }
    
    /// Estimated file size of the track in bytes.
    var estimatedFileSize: Int {
        let dataRateInBytes = Double(estimatedDataRate / 8)
        return Int(timeRange.duration.seconds * dataRateInBytes)
    }
}
