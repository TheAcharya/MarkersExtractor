//
//  AnimatedImageExtractorError.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// Animated image extraction error.
public enum AnimatedImageExtractorError: LocalizedError {
    case internalInconsistency(_ verboseError: String)
    case unreadableFile
    case noVideoTracks
    case couldNotDetermineFrameRate(Error)
    case couldNotDetermineVideoTrackDuration(Error)
    case gifInitializationFailed
    case gifFinalizationFailed
    case notEnoughFrames(Int)
    case generateFrameFailed(Swift.Error)
    case addFrameFailed(Swift.Error)
    case writeFailed(Swift.Error)
    
    public var errorDescription: String? {
        switch self {
        case let .internalInconsistency(verboseError):
            return "Internal error occurred: \(verboseError)"
        case .unreadableFile:
            return "The selected file is no longer readable."
        case .noVideoTracks:
            return "The media file does not contain a video track."
        case let .couldNotDetermineFrameRate(error):
            return "Could not determine the media file's frame rate. \(error.localizedDescription)"
        case let .couldNotDetermineVideoTrackDuration(error):
            return "Could not determine the media file's video track duration. \(error.localizedDescription)"
        case .gifInitializationFailed:
            return "Failed to initialize GIF file."
        case .gifFinalizationFailed:
            return "Failed to finalize GIF file."
        case let .notEnoughFrames(frameCount):
            let framesString = "\(frameCount) frame\(frameCount == 1 ? "" : "s")"
            return "An animated GIF requires a minimum of 2 frames but the video contains \(framesString)."
        case let .generateFrameFailed(error):
            return "Failed to generate frame: \(error.localizedDescription)"
        case let .addFrameFailed(error):
            return "Failed to add frame, with underlying error: \(error.localizedDescription)"
        case let .writeFailed(error):
            return "Failed to write, with underlying error: \(error.localizedDescription)"
        }
    }
}
