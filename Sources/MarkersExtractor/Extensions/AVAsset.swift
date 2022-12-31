//
//  AVAsset.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation

extension AVAsset {
    /// Whether the first video track is decodable.
    var isVideoDecodable: Bool {
        guard isReadable,
              let firstVideoTrack = tracks(withMediaType: .video).first
        else {
            return false
        }
        
        return firstVideoTrack.isDecodable
    }
    
    /// Returns a boolean of whether there are any video tracks.
    var hasVideo: Bool { !tracks(withMediaType: .video).isEmpty }
    
    /// Returns a boolean of whether there are any audio tracks.
    var hasAudio: Bool { !tracks(withMediaType: .audio).isEmpty }
    
    /// Returns the first video track if any.
    var firstVideoTrack: AVAssetTrack? { tracks(withMediaType: .video).first }
    
    /// Returns the first audio track if any.
    var firstAudioTrack: AVAssetTrack? { tracks(withMediaType: .audio).first }
    
    /// Returns the dimensions of the first video track if any.
    var dimensions: CGSize? { firstVideoTrack?.dimensions }
    
    /// Returns the frame rate of the first video track if any.
    var frameRate: Double? { firstVideoTrack?.frameRate }
    
    /// Returns the aspect ratio of the first video track if any.
    var aspectRatio: Double? { firstVideoTrack?.aspectRatio }
    
    /// Returns the video codec of the first video track if any.
    var videoCodec: AVFormat? { firstVideoTrack?.codec }
    
    /// Returns the audio codec of the first audio track if any.
    ///
    /// Example: `aac`
    var audioCodec: String? { firstAudioTrack?.codecIdentifier }
    
    /// The file size of the asset in bytes.
    ///
    /// - Note: If self is an `AVAsset` and not an `AVURLAsset`, this will be an estimate.
    var fileSize: Int {
        guard let urlAsset = self as? AVURLAsset else {
            return tracks.sum(\.estimatedFileSize)
        }
        
        return urlAsset.url.fileSize
    }
    
    var fileSizeFormatted: String { fileSize.bytesFormattedAsFileSize }
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
