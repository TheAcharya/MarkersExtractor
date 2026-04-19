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
            "hvc1"
        case .h264:
            "avc1"
        case .av1:
            "av01"
        case .vp9:
            "vp09"
        case .appleProResRAWHQ:
            "aprh"
        case .appleProResRAW:
            "aprn"
        case .appleProRes4444XQ:
            "ap4x"
        case .appleProRes4444:
            "ap4h"
        case .appleProRes422HQ:
            "apcn"
        case .appleProRes422:
            "apch"
        case .appleProRes422LT:
            "apcs"
        case .appleProRes422Proxy:
            "apco"
        case .appleAnimation:
            "rle "
        case .hap1:
            "Hap1"
        case .hap5:
            "Hap5"
        case .hapY:
            "HapY"
        case .hapM:
            "HapM"
        case .hapA:
            "HapA"
        case .hap7:
            "Hap7"
        case .cineFormHD:
            "CFHD"
        case .quickTimeGraphics:
            "smc"
        case .avidDNxHD:
            "AVdh"
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
            "HEVC"
        case .h264:
            "H264"
        case .av1:
            "AV1"
        case .vp9:
            "VP9"
        case .appleProResRAWHQ:
            "Apple ProRes RAW HQ"
        case .appleProResRAW:
            "Apple ProRes RAW"
        case .appleProRes4444XQ:
            "Apple ProRes 4444 XQ"
        case .appleProRes4444:
            "Apple ProRes 4444"
        case .appleProRes422HQ:
            "Apple ProRes 422 HQ"
        case .appleProRes422:
            "Apple ProRes 422"
        case .appleProRes422LT:
            "Apple ProRes 422 LT"
        case .appleProRes422Proxy:
            "Apple ProRes 422 Proxy"
        case .appleAnimation:
            "Apple Animation"
        case .hap1:
            "Vidvox Hap"
        case .hap5:
            "Vidvox Hap Alpha"
        case .hapY:
            "Vidvox Hap Q"
        case .hapM:
            "Vidvox Hap Q Alpha"
        case .hapA:
            "Vidvox Hap Alpha-Only"
        case .hap7:
            // No official name for this.
            "Vidvox Hap"
        case .cineFormHD:
            "CineForm HD"
        case .quickTimeGraphics:
            "QuickTime Graphics"
        case .avidDNxHD:
            "Avid DNxHD"
        }
    }
}

extension AVFormat: CustomDebugStringConvertible {
    var debugDescription: String {
        "\(description) (\(fourCC.trimmingCharacters(in: .whitespaces)))"
    }
}
