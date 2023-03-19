//
//  ExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections

public protocol ExportMarker {
    associatedtype Icon: ExportIcon
    
    var imageFileName: String { get }
    var icon: Icon { get }
    //var mediaInfo: ExportMarkerMediaInfo? { get }
}

public struct ExportMarkerMediaInfo {
    public var imageFormat: MarkerImageFormat
    public var isSingleFrame: Bool
    
    public init(imageFormat: MarkerImageFormat, isSingleFrame: Bool) {
        self.imageFormat = imageFormat
        self.isSingleFrame = isSingleFrame
    }
    
    public func imageFileName(for marker: Marker, idMode: MarkerIDMode) -> String {
        isSingleFrame
            ? "marker-placeholder.\(imageFormat)"
            : "\(marker.id(pathSafe: idMode)).\(imageFormat)"
    }
}
