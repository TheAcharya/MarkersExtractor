//
//  CMTime.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreMedia

extension CMTimeRange {
    /// Get `self` as a range in seconds.
    ///
    /// Can be `nil` when the range is not available, for example, when an asset has not yet been
    /// fully loaded or if it's a live stream.
    var range: ClosedRange<Double>? {
        guard start.isNumeric,
              end.isNumeric
        else {
            return nil
        }
        
        return start.seconds ... end.seconds
    }
}

extension CMTimeScale {
    /// Apple-recommended scale for video.
    ///
    /// ```
    /// CMTime(seconds: (1 / fps), preferredTimescale: .video)
    /// ```
    static let video: Self = 600
}
