//
//  Graphics Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import AppKit
import CoreGraphics

// MARK: - Basic Types

extension CGSize {
    init(widthHeight: Double) {
        self.init(width: widthHeight, height: widthHeight)
    }
    
    var longestSide: Double { max(width, height) }
    
    /// Formatted string. Example: "640×480"
    var formatted: String {
        "\(Double(width).formatted)×\(Double(height).formatted)"
    }
    
    static func * (lhs: Self, rhs: Double) -> Self {
        .init(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    var cgRect: CGRect { .init(origin: .zero, size: self) }
}

extension NSColor {
    // https://stackoverflow.com/a/33397427
    convenience init(hexString: String, alpha: Double) {
        var int = UInt64()
        let r: UInt64
        let g: UInt64
        let b: UInt64
        
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 3:  // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Images

extension NSImage {
    /// `UIImage` polyfill.
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
}

extension CGImage {
    static let empty = NSImage(size: CGSize(widthHeight: 1), flipped: false) { _ in true }
        .cgImage(forProposedRect: nil, context: nil, hints: nil)
    
    var nsImage: NSImage {
        NSImage(cgImage: self)
    }

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

extension CGImage {
    /// Debug info for the image.
    ///
    /// ```
    /// print(image.debugInfo)
    /// ```
    var debugInfo: String {
        """
        ## CGImage debug info ##
        Dimension: \(size.formatted)
        Pixel format: \(bitmapInfo.pixelFormat?.title ?? "Unknown")
        Premultiplied alpha: \(bitmapInfo.isPremultipliedAlpha)
        Color space: \(colorSpace?.title ?? "nil")
        """
    }
}

extension CGImage {
    enum PixelFormat {
        /// Big-endian, alpha first.
        case argb
        
        /// Big-endian, alpha last.
        case rgba
        
        /// Little-endian, alpha first.
        case bgra
        
        /// Little-endian, alpha last.
        case abgr
        
        var title: String {
            switch self {
            case .argb:
                return "ARGB"
            case .rgba:
                return "RGBA"
            case .bgra:
                return "BGRA"
            case .abgr:
                return "ABGR"
            }
        }
    }
}

// MARK: - Graphics Metadata

extension CGBitmapInfo {
    /// The alpha info of the current `CGBitmapInfo`.
    var alphaInfo: CGImageAlphaInfo {
        get {
            CGImageAlphaInfo(rawValue: rawValue & Self.alphaInfoMask.rawValue) ?? .none
        }
        set {
            remove(.alphaInfoMask)
            insert(.init(rawValue: newValue.rawValue))
        }
    }
    
    /// The pixel format of the image.
    ///
    /// Returns `nil` if the pixel format is not supported, for example, non-alpha.
    var pixelFormat: CGImage.PixelFormat? {
        // While the host byte order is little-endian, by default, `CGImage` is stored in big-endian
        // format on Intel Macs and little-endian on Apple silicon Macs.
        
        let alphaInfo = alphaInfo
        let isLittleEndian = contains(.byteOrder32Little)
        
        guard alphaInfo != .none else {
            // TODO: Support non-alpha formats.
            // return isLittleEndian ? .bgr : .rgb
            return nil
        }
        
        let isAlphaFirst = alphaInfo == .premultipliedFirst
            || alphaInfo == .first
            || alphaInfo == .noneSkipFirst
        
        if isLittleEndian {
            return isAlphaFirst ? .bgra : .abgr
        } else {
            return isAlphaFirst ? .argb : .rgba
        }
    }
    
    /// Whether the alpha channel is pre-multipled.
    var isPremultipliedAlpha: Bool {
        let alphaInfo = alphaInfo
        return alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }
}

extension CGColorSpace {
    /// Presentable title of the color space.
    var title: String {
        guard let name = name else {
            return "Unknown"
        }
        
        return (name as String).replacingOccurrences(
            of: #"^kCGColorSpace"#,
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
}
