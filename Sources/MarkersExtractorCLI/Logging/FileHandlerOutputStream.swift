//
//  FileHandlerOutputStream.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation

struct FileHandlerOutputStream: TextOutputStream {
    let queue = DispatchQueue(label: "FileHandlerOutputStream", qos: .default)
    
    let encoding: String.Encoding
    
    private let fileHandle: FileHandle
    
    init(localFile url: URL, encoding: String.Encoding = .utf8) throws {
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            else {
                throw StreamError.couldNotCreateFile
            }
        }
        
        fileHandle = try FileHandle(forWritingTo: url)
        try fileHandle.seekToEnd()
        self.encoding = encoding
    }
}

extension FileHandlerOutputStream: Sendable { }

extension FileHandlerOutputStream {
    mutating func write(_ string: String) {
        guard let data = string.data(using: encoding) else { return }
        queue.sync { [self] in
            do {
                try fileHandle.write(contentsOf: data)
            } catch {
                #if DEBUG
                print(error)
                #endif
            }
        }
    }
}

extension FileHandlerOutputStream {
    enum StreamError: Error {
        case couldNotCreateFile
    }
}
