//
//  MIDIFileExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKitCore

public struct MIDIFileExportMarker: ExportMarker {
    public typealias Icon = EmptyExportIcon
    
    public let position: String
    public let name: String
    public let frameRate: TimecodeFrameRate
    public let subFramesBase: Timecode.SubFramesBase
    
    public var icon: EmptyExportIcon {
        .init(.standard) // never used, just dummy
    }
    
    public let imageFileName: String
    public let imageTimecode: Timecode // not used
    
    public init(
        marker: Marker,
        idMode: MarkerIDMode,
        timeFormat: ExportMarkerTimeFormat
    ) {
        name = marker.name
        position = marker.positionTimeString(format: timeFormat)
        frameRate = marker.frameRate()
        subFramesBase = marker.subFramesBase()
        imageFileName = UUID().uuidString // never used, just dummy
        imageTimecode = marker.imageTimecode(useChapterMarkerPosterOffset: false, offsetToTimelineStart: false) // not used
    }
    
    /// Convert to a DAWFileKit `DAWMarker`.
    func dawMarker() -> DAWMarker {
        DAWMarker(
            storage: .init(
                value: .timecodeString(absolute: position),
                frameRate: frameRate,
                base: subFramesBase
            ),
            name: name,
            comment: nil
        )
    }
}
