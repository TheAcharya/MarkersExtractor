//
//  ExportIcon.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

public protocol ExportIcon: Equatable, Hashable {
    var resource: EmbeddedResource { get }
    var fileName: String { get }
    var data: Data { get }
    init(_ type: MarkerType)
}
