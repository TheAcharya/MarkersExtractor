//
//  MarkersExtractor Metadata.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKit

extension MarkersExtractor {
    func startTimecode(forProject project: FinalCutPro.FCPXML.Project) -> Timecode {
        if let tc = project.startTimecode {
            logger.info(
                "Project start timecode: \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        } else if let frameRate = project.frameRate {
            let tc = Timecode(.zero, at: frameRate, base: .max100SubFrames)
            logger.warning(
                "Could not determine project start timecode. Defaulting to \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        } else {
            let tc = Timecode(.zero, at: .fps30, base: .max100SubFrames)
            logger.warning(
                "Could not determine project start timecode. Defaulting to \(tc.stringValue(format: timecodeStringFormat)) @ \(tc.frameRate.stringValueVerbose)."
            )
            return tc
        }
    }
    
    var timecodeStringFormat: Timecode.StringFormat {
        s.enableSubframes ? [.showSubFrames] : .default()
    }
}

extension MarkersExtractor {
    static let elementContext: FCPXMLElementContextBuilder = .group([
        .default,
        MarkerContext()
    ])
    
    struct MarkerContext: FCPXMLElementContextBuilder {
        init() { }
        
        var contextBuilder: FinalCutPro.FCPXML.ElementContextClosure {
            { xmlLeaf, breadcrumbs, resources, tools in
                var dict: FinalCutPro.FCPXML.ElementContext = [:]
                dict = [:] // silence build warning since we commented out stuff below
                
                // not storing this for now, because we don't need it yet
                // dict[.resource] = tools.resource
                
                // we're not using this, as it's not consistent.
                // basic clips like asset clips only have one media file used,
                // but sync clips, multicam, and compount clips (ref-clip) can
                // have multiple clips with multiple media files so it would be ambiguous.
                // dict[.mediaFilename] = tools.mediaURL?.lastPathComponent
                
                return dict
            }
        }
    }
}

// MARK: - Dictionary Keys

extension FinalCutPro.FCPXML.ContextKey {
    fileprivate enum Key: String, Equatable, Hashable {
        case resource
    }
    
    // not storing this for now, because we don't need it yet
    // /// The absolute start timecode of the element.
    // public static var resource: FinalCutPro.FCPXML.ContextKey<FinalCutPro.FCPXML.AnyResource> {
    //     .init(key: Key.resource)
    // }
}
