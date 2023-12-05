//
//  JSON Export Utils.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CodableCSV
import Foundation
import OrderedCollections

extension ExportProfile {
    func jsonWriteManifest(
        jsonPath: URL,
        noMedia: Bool,
        _ preparedMarkers: [PreparedMarker]
    ) throws {
        let orderedDicts = jsonDicts(preparedMarkers, noMedia: noMedia)
        let dicts = orderedDicts.map { orderedDictToDict($0) }
        let data = try dictsToJSON(dicts)
        try data.write(to: jsonPath)
    }
    
    // MARK: Helpers
    
    private func jsonDicts(
        _ preparedMarkers: [PreparedMarker],
        noMedia: Bool
    ) -> [OrderedDictionary<String, ExportFieldValue>] {
        preparedMarkers.map {
            nestedManifestFields(for: $0, noMedia: noMedia)
                .reduce(into: OrderedDictionary<String, ExportFieldValue>()) {
                    $0[$1.key.name] = $1.value
                }
        }
    }
}

func dictToJSON(_ dict: [String: String]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    return try encoder.encode(dict)
}

func dictToJSON(_ dict: [String: ExportFieldValue]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    return try encoder.encode(dict)
}

func dictsToJSON(_ dict: [[String: ExportFieldValue]]) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    return try encoder.encode(dict)
}

func orderedDictToDict<K, V>(_ orderedDict: OrderedDictionary<K, V>) -> [K: V] {
    orderedDict.reduce(into: [K: V]()) {
        $0[$1.key] = $1.value
    }
}
