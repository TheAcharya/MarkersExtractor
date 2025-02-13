//
//  ImageWriterProtocol.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

protocol ImageWriterProtocol {
    var progress: Progress { get }
    func write() async throws
}
