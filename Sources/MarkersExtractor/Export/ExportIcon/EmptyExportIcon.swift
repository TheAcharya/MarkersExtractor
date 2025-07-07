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
    
    public init(_ configuration: FinalCutPro.FCPXML.Marker.Configuration) { }
    
    public init(_ type: InterpretedMarkerType) { }
}

extension EmptyExportIcon: Equatable { }

extension EmptyExportIcon: Hashable { }

extension EmptyExportIcon: Sendable { }

extension EmptyExportIcon {
    public init() { }
}
