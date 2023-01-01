//
//  ExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections

public protocol ExportMarker {
    associatedtype Field: ExportField
    associatedtype Icon: ExportIcon
    
    var imageFileName: String { get }
    var icon: Icon { get }
}
