//
//  AVFormat.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation

enum AVFormat: String {
    case hevc
    case h264
    case av1
    case vp9
    case appleProResRAWHQ
    case appleProResRAW
    case appleProRes4444XQ
    case appleProRes4444
    case appleProRes422HQ
    case appleProRes422
    case appleProRes422LT
    case appleProRes422Proxy
    case appleAnimation
    
    // https://hap.video/using-hap.html
    // https://github.com/Vidvox/hap/blob/master/documentation/HapVideoDRAFT.md#names-and-identifiers
    case hap1
    case hap5
    case hapY
    case hapM
    case hapA
    case hap7
    
    case cineFormHD
    
    // https://en.wikipedia.org/wiki/QuickTime_Graphics
    case quickTimeGraphics
    
    // https://en.wikipedia.org/wiki/Avid_DNxHD
    case avidDNxHD
}
extension AVFormat: Equatable { }

extension AVFormat: Hashable { }

extension AVFormat: CaseIterable { }

extension AVFormat: Sendable { }

// MARK: - FourCC Init & Property

extension AVFormat {
    init?(fourCC: String) {
        let sanitizedFourCC = fourCC.trimmingCharacters(in: .whitespaces)
        
        guard let match = Self.allCases.first(where: { $0.fourCC == sanitizedFourCC })
        else { return nil }
        
        self = match
    }
    
    init?(fourCC: FourCharCode) {
        self.init(fourCC: fourCC.fourCharCodeToString())
    }
    
    var fourCC: String {
        switch self {
        case .hevc:
            return "hvc1"
        case .h264:
            return "avc1"
        case .av1:
            return "av01"
        case .vp9:
            return "vp09"
        case .appleProResRAWHQ:
            return "aprh"
        case .appleProResRAW:
            return "aprn"
        case .appleProRes4444XQ:
            return "ap4x"
        case .appleProRes4444:
            return "ap4h"
        case .appleProRes422HQ:
            return "apcn"
        case .appleProRes422:
            return "apch"
        case .appleProRes422LT:
            return "apcs"
        case .appleProRes422Proxy:
            return "apco"
        case .appleAnimation:
            return "rle "
        case .hap1:
            return "Hap1"
        case .hap5:
            return "Hap5"
        case .hapY:
            return "HapY"
        case .hapM:
            return "HapM"
        case .hapA:
            return "HapA"
        case .hap7:
            return "Hap7"
        case .cineFormHD:
            return "CFHD"
        case .quickTimeGraphics:
            return "smc"
        case .avidDNxHD:
            return "AVdh"
        }
    }
}

// MARK: - Properties

extension AVFormat {
    var isAppleProRes: Bool {
        [
            .appleProResRAWHQ,
            .appleProResRAW,
            .appleProRes4444XQ,
            .appleProRes4444,
            .appleProRes422HQ,
            .appleProRes422,
            .appleProRes422LT,
            .appleProRes422Proxy
        ].contains(self)
    }
    
    /// > Important:
    /// >
    /// > This check only covers known (by us) compatible formats. It might be missing some.
    /// > Don't use it for strict matching. Also keep in mind that even though a codec is
    /// > supported, it might still not be decodable as the codec profile level might not be
    /// > supported.
    var isSupported: Bool {
        self == .hevc || self == .h264 || isAppleProRes
    }
}

extension AVFormat: CustomStringConvertible {
    var description: String {
        switch self {
        case .hevc:
            return "HEVC"
        case .h264:
            return "H264"
        case .av1:
            return "AV1"
        case .vp9:
            return "VP9"
        case .appleProResRAWHQ:
            return "Apple ProRes RAW HQ"
        case .appleProResRAW:
            return "Apple ProRes RAW"
        case .appleProRes4444XQ:
            return "Apple ProRes 4444 XQ"
        case .appleProRes4444:
            return "Apple ProRes 4444"
        case .appleProRes422HQ:
            return "Apple ProRes 422 HQ"
        case .appleProRes422:
            return "Apple ProRes 422"
        case .appleProRes422LT:
            return "Apple ProRes 422 LT"
        case .appleProRes422Proxy:
            return "Apple ProRes 422 Proxy"
        case .appleAnimation:
            return "Apple Animation"
        case .hap1:
            return "Vidvox Hap"
        case .hap5:
            return "Vidvox Hap Alpha"
        case .hapY:
            return "Vidvox Hap Q"
        case .hapM:
            return "Vidvox Hap Q Alpha"
        case .hapA:
            return "Vidvox Hap Alpha-Only"
        case .hap7:
            // No official name for this.
            return "Vidvox Hap"
        case .cineFormHD:
            return "CineForm HD"
        case .quickTimeGraphics:
            return "QuickTime Graphics"
        case .avidDNxHD:
            return "Avid DNxHD"
        }
    }
}

extension AVFormat: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(description) (\(fourCC.trimmingCharacters(in: .whitespaces)))"
    }
}
