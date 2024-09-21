//
//  ExportMarkerTimeFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKit
import OTCore

public enum ExportMarkerTimeFormat: Equatable, Hashable {
    case timecode(stringFormat: Timecode.StringFormat)
    case realTime(stringFormat: Time.Format)
}

extension ExportMarkerTimeFormat: Identifiable {
    public var id: Self { self }
}
