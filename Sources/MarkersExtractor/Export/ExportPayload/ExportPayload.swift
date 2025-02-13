//
//  ExportPayload.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

/// An object containing data that is proprietary only to the specific export profile.
public protocol ExportPayload: Equatable, Hashable where Self: Sendable { }
