//
//  ExportMarkerTimeFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import TimecodeKitCore
import OTCore

public enum ExportMarkerTimeFormat {
    /// Timecode.
    case timecode(stringFormat: Timecode.StringFormat)
    
    /// Real (wall) time.
    case realTime(stringFormat: Time.Format)
    
    /// SRT (SubRip) encoded.
    case srt
}

extension ExportMarkerTimeFormat: Equatable { }

extension ExportMarkerTimeFormat: Hashable { }

extension ExportMarkerTimeFormat: Identifiable {
    public var id: Self { self }
}

extension ExportMarkerTimeFormat: Sendable { }
