//
//  ExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections
import TimecodeKitCore

public protocol ExportMarker: Equatable, Hashable where Self: Sendable {
    associatedtype Icon: ExportIcon
    
    var imageFileName: String { get }
    var imageTimecode: Timecode { get }
    var icon: Icon { get }
}
