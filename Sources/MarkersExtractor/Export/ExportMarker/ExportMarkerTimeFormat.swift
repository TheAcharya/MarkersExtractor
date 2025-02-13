//
//  ExportMarkerTimeFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKitCore
import OTCore

public enum ExportMarkerTimeFormat {
    case timecode(stringFormat: Timecode.StringFormat)
    case realTime(stringFormat: Time.Format)
}

extension ExportMarkerTimeFormat: Equatable { }

extension ExportMarkerTimeFormat: Hashable { }

extension ExportMarkerTimeFormat: Identifiable {
    public var id: Self { self }
}

extension ExportMarkerTimeFormat: Sendable { }
