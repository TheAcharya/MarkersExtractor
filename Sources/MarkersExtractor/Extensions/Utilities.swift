//
//  Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import AppKit
import CoreGraphics

// MARK: - Standard Lib

extension Double {
    /// Converts the number to a string and strips fractional trailing zeros.
    ///
    /// ```
    /// print(1.0)
    /// // "1.0"
    ///
    /// print(1.0.formatted)
    /// // "1"
    ///
    /// print(0.0100.formatted)
    /// // "0.01"
    /// ```
    var formatted: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension Comparable {
    func clamped(from lowerBound: Self, to upperBound: Self) -> Self {
        min(max(self, lowerBound), upperBound)
    }
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }
    
    func clamped(to range: PartialRangeThrough<Self>) -> Self {
        min(self, range.upperBound)
    }
    
    func clamped(to range: PartialRangeFrom<Self>) -> Self {
        max(self, range.lowerBound)
    }
}

extension Strideable where Stride: SignedInteger {
    func clamped(to range: CountableRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound.advanced(by: -1))
    }
    
    func clamped(to range: CountableClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }
    
    func clamped(to range: PartialRangeUpTo<Self>) -> Self {
        min(self, range.upperBound.advanced(by: -1))
    }
}

extension ClosedRange where Bound: AdditiveArithmetic {
    /// Get the length between the lower and upper bound.
    var length: Bound { upperBound - lowerBound }
}

extension Sequence {
    /// Returns the sum of elements in a sequence by mapping the elements with a numerator.
    ///
    /// ```
    /// [1, 2, 3].sum { $0 == 1 ? 10 : $0 }
    /// // 15
    /// ```
    func sum<T: AdditiveArithmetic>(_ numerator: (Element) throws -> T) rethrows -> T {
        var result = T.zero
        
        for element in self {
            result += try numerator(element)
        }
        
        return result
    }
}

extension String {
    /// Wraps a string with double-quotes (`"`)
    @_disfavoredOverload
    public var quoted: Self {
        "\"\(self)\""
    }
}

// MARK: - FileManager

extension FileManager {
    func fileIsDirectory(_ path: String) -> Bool {
        var fileIsDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &fileIsDirectory
        )
        return fileExists && fileIsDirectory.boolValue
    }
    
    func mkdirWithParent(_ path: String, reuseExisting: Bool = false) throws {
        if FileManager.default.fileExists(atPath: path) {
            if reuseExisting, fileIsDirectory(path) {
                return
            } else {
                throw MarkersExtractorError
                    .runtimeError("Directory with path already exists: \(path)")
            }
        }
        
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}

// MARK: - URL

extension URL {
    var fileExtension: String {
        get { pathExtension }
        set {
            deletePathExtension()
            appendPathExtension(newValue)
        }
    }
    
    /// File size in bytes.
    var fileSize: Int { resourceValue(forKey: .fileSizeKey) ?? 0 }
    
    // MARK: Helpers
    
    private func resourceValue<T>(forKey key: URLResourceKey) -> T? {
        guard let values = try? resourceValues(forKeys: [key]) else {
            return nil
        }
        
        return values.allValues[key] as? T
    }
    
    private func boolResourceValue(forKey key: URLResourceKey, defaultValue: Bool = false) -> Bool {
        guard let values = try? resourceValues(forKeys: [key]) else {
            return defaultValue
        }
        
        return values.allValues[key] as? Bool ?? defaultValue
    }
}

extension FixedWidthInteger {
    /// Returns the integer formatted as a human readable file size.
    ///
    /// Example: `2.3 GB`
    var bytesFormattedAsFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

// MARK: - Data / Encoding

// FourCharCode is short for "four character code".
// An identifier for a video codec, compression format, color or pixel format used in media files.
extension FourCharCode {
    /// Create a String representation of a FourCC.
    func fourCharCodeToString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xFF),
            CChar((self >> 16) & 0xFF),
            CChar((self >> 8) & 0xFF),
            CChar(self & 0xFF),
            0x00
        ]
        
        return String(cString: bytes)
            .trimmingCharacters(in: .whitespaces)
    }
}

extension URL {
    /// Form a URL to a resource file contained within this Swift package.
    init?(
        moduleResource: String,
        withExtension: String,
        subFolder: String? = nil
    ) {
        guard let url = Bundle.module.url(
            forResource: moduleResource,
            withExtension: withExtension,
            subdirectory: subFolder
        ) else { return nil }
        self = url
    }
    
    var exists: Bool { FileManager.default.fileExists(atPath: path) }
    
    var isReadable: Bool { boolResourceValue(forKey: .isReadableKey) }
    
    var isWritable: Bool { boolResourceValue(forKey: .isWritableKey) }
}
