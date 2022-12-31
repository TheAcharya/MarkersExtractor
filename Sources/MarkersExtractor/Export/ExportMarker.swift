//
//  ExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections

public protocol ExportMarker {
    associatedtype Field: ExportField
    
    var imageFileName: String { get }
    
    func dictionaryRepresentation() -> OrderedDictionary<Field, String>
}
