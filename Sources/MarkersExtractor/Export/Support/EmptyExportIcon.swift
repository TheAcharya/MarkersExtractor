//
//  EmptyExportIcon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

/// `ExportIcon` prototype that can be used when a profile does not use marker icons.
public struct EmptyExportIcon: ExportIcon {
    public var resource: EmbeddedResource = .empty_png // ignore
    
    public var fileName: String = ""
    
    public let data: Data = .init()
    
    public init(_ type: FinalCutPro.FCPXML.Marker.MarkerMetaData) { }
    
    public init(_ type: InterpretedMarkerType) { }
}
