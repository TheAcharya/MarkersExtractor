//
//  EmptyExportIcon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// `ExportIcon` prototype that can be used when a profile does not use marker icons.
public struct EmptyExportIcon: ExportIcon {
    public var resource: EmbeddedResource = .notion_marker_png // ignore
    
    public var fileName: String = "empty.png"
    
    public let data: Data = Data()
    
    public init(_ type: MarkerType) { }
}
