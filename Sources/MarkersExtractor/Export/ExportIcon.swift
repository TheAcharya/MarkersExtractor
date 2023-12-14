//
//  ExportIcon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation

public protocol ExportIcon: Equatable, Hashable {
    var resource: EmbeddedResource { get }
    var fileName: String { get }
    var data: Data { get }
    init(_ configuration: FinalCutPro.FCPXML.Marker.MarkerConfiguration)
    init(_ type: InterpretedMarkerType)
}
