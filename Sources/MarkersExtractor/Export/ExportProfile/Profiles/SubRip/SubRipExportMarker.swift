//
//  SubRipExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileTools
import Foundation
import SwiftExtensions
import SwiftTimecodeCore

public struct SubRipExportMarker: ExportMarker {
    public typealias Icon = EmptyExportIcon
    
    public let inTime: Time
    public let outTime: Time
    public let name: String
    
    public var icon: EmptyExportIcon {
        .init(.standard)
    }
    
    public let imageFileName: String
    public let imageTimecode: Timecode
    
    
    public init(
        marker: Marker,
        idMode: MarkerIDMode,
        timeFormat: ExportMarkerTimeFormat
    ) {
        name = marker.name
        
        inTime = Time(seconds: marker.positionOffsetFromTimelineStart().realTimeValue)
        
        // calculate out time by using a duration heuristic
        let durationPerCharacter: TimeInterval = 0.03
        let duration = (TimeInterval(marker.name.trimmed.count) * durationPerCharacter)
            .clamped(to: 1.0 ... 5.0) // min and max duration
        outTime = inTime + Time(seconds: duration)
        
        imageFileName = UUID().uuidString
        imageTimecode = marker.imageTimecode(useChapterMarkerPosterOffset: false, offsetToTimelineStart: false)
    }
}
