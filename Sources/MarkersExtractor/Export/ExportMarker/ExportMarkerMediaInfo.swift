//
//  ExportMarkerMediaInfo.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TimecodeKitCore

public struct ExportMarkerMediaInfo {
    public var imageFormat: MarkerImageFormat
    public var isSingleFrame: Bool
    
    public init(imageFormat: MarkerImageFormat, isSingleFrame: Bool) {
        self.imageFormat = imageFormat
        self.isSingleFrame = isSingleFrame
    }
}

extension ExportMarkerMediaInfo: Equatable { }

extension ExportMarkerMediaInfo: Hashable { }

extension ExportMarkerMediaInfo: Sendable { }

// MARK: - Methods

extension ExportMarkerMediaInfo {
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
