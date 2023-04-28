//
//  JSON Done File.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import OrderedCollections

extension ExportProfile {
    public func jsonDoneFileContent(jsonPath: URL) -> [String: String] {
        ["jsonPath": jsonPath.path]
    }
    
    public func jsonDoneFileData(jsonPath: URL) throws -> Data {
        try dictToJSON(jsonDoneFileContent(jsonPath: jsonPath))
    }
}
