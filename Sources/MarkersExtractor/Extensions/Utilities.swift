//
//  Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import CoreGraphics
import Foundation

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
    package var formatted: String {
        truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

extension Comparable {
    package func clamped(from lowerBound: Self, to upperBound: Self) -> Self {
        min(max(self, lowerBound), upperBound)
    }
    
    package func clamped(to range: ClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }
    
    package func clamped(to range: PartialRangeThrough<Self>) -> Self {
        min(self, range.upperBound)
    }
    
    package func clamped(to range: PartialRangeFrom<Self>) -> Self {
        max(self, range.lowerBound)
    }
}

extension Strideable where Stride: SignedInteger {
    package func clamped(to range: CountableRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound.advanced(by: -1))
    }
    
    package func clamped(to range: CountableClosedRange<Self>) -> Self {
        clamped(from: range.lowerBound, to: range.upperBound)
    }
    
    package func clamped(to range: PartialRangeUpTo<Self>) -> Self {
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
    package func sum<T: AdditiveArithmetic>(_ numerator: (Element) throws -> T) rethrows -> T {
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
    package var quoted: Self {
        "\"\(self)\""
    }
}

// MARK: - FileManager

extension FileManager {
    package func fileIsDirectory(_ path: String) -> Bool {
        var fileIsDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(
            atPath: path,
            isDirectory: &fileIsDirectory
        )
        return fileExists && fileIsDirectory.boolValue
    }
    
    package func mkdirWithParent(_ path: String, reuseExisting: Bool = false) throws {
        if FileManager.default.fileExists(atPath: path) {
            if reuseExisting, fileIsDirectory(path) {
                return
            } else {
                throw MarkersExtractorError.extraction(.outputFolderAlreadyExists(
                    "Directory with path already exists: \(path.quoted)"
                ))
            }
        }
        
        do {
            try FileManager.default.createDirectory(
                atPath: path,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            // we're just assuming this fails because of a permission issue, but it could be
            // something else
            throw MarkersExtractorError.extraction(
                .filePermission(error.localizedDescription)
            )
        }
    }
    
    /// Returns input if the proposed path does not exist.
    /// Uniques the file or folder name if it already exists by incrementing a trailing integer.
    /// ie: "File.png", "File (1).png", "File (2).png", etc.
    package func uniqueFileURL(proposedPath url: URL) -> URL {
        var url = url
        var counter = 1
        
        let parentFolder = url.deletingLastPathComponent()
        let filenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.fileExtension
        
        while fileExists(atPath: url.path) {
            counter += 1
            
            let newFileName = "\(filenameWithoutExtension) (\(counter))"
            url = parentFolder.appendingPathComponent(newFileName)
            if let fileExtension {
                url.appendPathExtension("\(fileExtension)")
            }
        }
        
        return url
    }
}

// MARK: - URL

extension URL {
    package var fileExtension: String? {
        get {
            // edge case for when filename ends with "." and no extension following
            if pathExtension.isEmpty, !lastPathComponent.contains(".") {
                return nil
            }
            return pathExtension
        }
        set {
            deletePathExtension()
            if let newValue = newValue {
                appendPathExtension(newValue)
            }
        }
    }
    
    /// File size in bytes.
    package var fileSize: Int { resourceValue(forKey: .fileSizeKey) ?? 0 }
    
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
    package var bytesFormattedAsFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

// MARK: - Data / Encoding

// FourCharCode is short for "four character code".
// An identifier for a video codec, compression format, color or pixel format used in media files.
extension FourCharCode { // a.k.a. UInt32
    /// Create a String representation of a FourCC.
    package func fourCharCodeToString() -> String {
        NSFileTypeForHFSTypeCode(self)
    }
}

extension URL {
    // Note: this only compiles if Package.swift contains `.resources: []` for this package target
    // /// Form a URL to a resource file contained within this Swift package.
    // package init?(
    //    moduleResource: String,
    //    withExtension: String,
    //    subFolder: String? = nil
    // ) {
    //    guard let url = Bundle.module.url(
    //        forResource: moduleResource,
    //        withExtension: withExtension,
    //        subdirectory: subFolder
    //    ) else { return nil }
    //    self = url
    // }
    
    package var exists: Bool { FileManager.default.fileExists(atPath: path) }
    
    package var isReadable: Bool { boolResourceValue(forKey: .isReadableKey) }
    
    package var isWritable: Bool { boolResourceValue(forKey: .isWritableKey) }
}

// MARK: - RegEx

extension StringProtocol {
    /// Returns an array of RegEx matches
    /// (Borrowed from OTCore 1.4.10, under MIT license)
    package func regexMatches(
        pattern: String,
        options: NSRegularExpression.Options = [],
        matchesOptions: NSRegularExpression.MatchingOptions = [.withTransparentBounds]
    ) -> [String] {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern,
                options: options
            )
            
            func runRegEx(in source: String) -> [NSTextCheckingResult] {
                regex.matches(
                    in: source,
                    options: matchesOptions,
                    range: NSMakeRange(0, nsString.length)
                )
            }
            
            let nsString: NSString
            let results: [NSTextCheckingResult]
            
            switch self {
            case let _self as String:
                nsString = _self as NSString
                results = runRegEx(in: _self)
                
            default:
                let stringSelf = String(self)
                nsString = stringSelf as NSString
                results = runRegEx(in: stringSelf)
            }
            
            return results.map { nsString.substring(with: $0.range) }
            
        } catch {
            return []
        }
    }
    
    /// Returns a string from a tokenized string of RegEx matches
    /// (Borrowed from OTCore 1.4.10, under MIT license)
    package func regexMatches(
        pattern: String,
        replacementTemplate: String,
        options: NSRegularExpression.Options = [],
        matchesOptions: NSRegularExpression.MatchingOptions = [.withTransparentBounds],
        replacingOptions: NSRegularExpression.MatchingOptions = [.withTransparentBounds]
    ) -> String? {
        do {
            let regex = try NSRegularExpression(
                pattern: pattern,
                options: options
            )
            
            func runRegEx(in source: String) -> String {
                regex.stringByReplacingMatches(
                    in: source,
                    options: replacingOptions,
                    range: NSMakeRange(0, source.count),
                    withTemplate: replacementTemplate
                )
            }
            
            let result: String
            
            switch self {
            case let _self as String:
                result = runRegEx(in: _self)
                
            default:
                let stringSelf = String(self)
                result = runRegEx(in: stringSelf)
            }
            
            return result
            
        } catch {
            return nil
        }
    }
    
    /// Returns capture groups from regex matches.
    /// If any capture group is not matched it will be `nil`.
    /// (Borrowed from OTCore 1.4.10, under MIT license)
    package func regexMatches(
        captureGroupsFromPattern: String,
        options: NSRegularExpression.Options = [],
        matchesOptions: NSRegularExpression.MatchingOptions = [.withTransparentBounds]
    ) -> [String?] {
        do {
            let regex = try NSRegularExpression(
                pattern: captureGroupsFromPattern,
                options: options
            )
            
            let result: [String?]
            
            func runRegEx(in source: String) -> [String?] {
                let results = regex.matches(
                    in: source,
                    options: matchesOptions,
                    range: NSMakeRange(0, source.count)
                )
                
                let nsString = source as NSString
                
                var matches: [String?] = []
                
                for result in results {
                    for i in 0 ..< result.numberOfRanges {
                        let range = result.range(at: i)
                        
                        if range.location == NSNotFound {
                            matches.append(nil)
                        } else {
                            matches.append(nsString.substring(with: range))
                        }
                    }
                }
                
                return matches
            }
            
            switch self {
            case let _self as String:
                result = runRegEx(in: _self)
                
            default:
                let stringSelf = String(self)
                result = runRegEx(in: stringSelf)
            }
            
            return result
            
        } catch {
            return []
        }
    }
}
