//
//  ExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TimecodeKit

public protocol ExportMarker {
    associatedtype Icon: ExportIcon
    
    var imageFileName: String { get }
    var imageTimecode: Timecode { get }
    var icon: Icon { get }
}

public struct ExportMarkerMediaInfo {
    public var imageFormat: MarkerImageFormat
    public var isSingleFrame: Bool
    
    public init(imageFormat: MarkerImageFormat, isSingleFrame: Bool) {
        self.imageFormat = imageFormat
        self.isSingleFrame = isSingleFrame
    }
    
    public func imageFileName(
        for marker: Marker,
        idMode: MarkerIDMode,
        tcStringFormat: Timecode.StringFormat
    ) -> String {
        isSingleFrame
            ? "marker-placeholder.\(imageFormat)"
            : "\(marker.id(pathSafe: idMode, tcStringFormat: tcStringFormat)).\(imageFormat)"
    }
}
