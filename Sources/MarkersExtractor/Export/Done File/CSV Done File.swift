//
//  CSV Done File.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CodableCSV
import Foundation
import OrderedCollections

extension ExportProfile {
    public func csvDoneFileContent(csvPath: URL) -> [String: String] {
        ["csvPath": csvPath.path]
    }
    
    public func csvDoneFileData(csvPath: URL) throws -> Data {
        try dictToJSON(csvDoneFileContent(csvPath: csvPath))
    }
}
