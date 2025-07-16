//
//  SubRipExportMarker.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import DAWFileKit
import Foundation
import TimecodeKitCore

public struct SubRipExportMarker: ExportMarker {
    public typealias Icon = EmptyExportIcon
    
    public let position: String
    public let name: String
    public let frameRate: TimecodeFrameRate
    public let subFramesBase: Timecode.SubFramesBase
    
    public var icon: EmptyExportIcon {
        .init(.standard)
    }
    
    public let imageFileName: String
    public let imageTimecode: Timecode
    
    public init(
        marker: Marker,
        idMode: MarkerIDMode,
        timeFormat: ExportMarkerTimeFormat
    ) {
        name = marker.name
        position = marker.positionTimeString(format: timeFormat)
        frameRate = marker.frameRate()
        subFramesBase = marker.subFramesBase()
        imageFileName = UUID().uuidString
        imageTimecode = marker.imageTimecode(useChapterMarkerPosterOffset: false, offsetToTimelineStart: false)
    }
    
    func convertToSRTTime(timecode: String) -> String {
        let components = timecode.components(separatedBy: ":")
        guard components.count >= 3 else { return "00:00:00,000" }
        
        let hours = Int(components[0]) ?? 0
        let minutes = Int(components[1]) ?? 0
        let seconds = Int(components[2]) ?? 0
        let frames = components.count > 3 ? (Int(components[3]) ?? 0) : 0
        
        // Calculate total frames based on the timecode
        let totalFrames = calculateTotalFrames(hours: hours, minutes: minutes, seconds: seconds, frames: frames)
        
        // Convert total frames to total seconds as a double
        let totalSeconds = convertFramesToSeconds(totalFrames: totalFrames)
        
        // Calculate new hours, minutes, seconds and milliseconds
        let newHours = Int(totalSeconds) / 3600
        let remainingSeconds1 = totalSeconds - Double(newHours * 3600)
        let newMinutes = Int(remainingSeconds1) / 60
        let remainingSeconds2 = remainingSeconds1 - Double(newMinutes * 60)
        let newSeconds = Int(remainingSeconds2)
        let newMilliseconds = Int(round((remainingSeconds2 - Double(newSeconds)) * 1000))
        
        return String(format: "%02d:%02d:%02d,%03d", newHours, newMinutes, newSeconds, newMilliseconds)
    }
    
    // Calculate total frames from timecode components, handling drop-frame when applicable
    private func calculateTotalFrames(hours: Int, minutes: Int, seconds: Int, frames: Int) -> Int {
        let frInfo = getFrameRateInfo(frameRate)
        let framesPerSecond = Int(frInfo.rate.rounded())
        let dropFrame = frInfo.isDropFrame
        
        // For non-drop frame, calculation is straightforward
        if !dropFrame {
            return hours * 3600 * framesPerSecond + 
                   minutes * 60 * framesPerSecond + 
                   seconds * framesPerSecond + 
                   frames
        }
        
                    // For 59.94 drop-frame
            if frInfo.rate.rounded() == 60 {
                // 59.94 drops 4 frames per minute except every 10th minute
                let totalMinutes = hours * 60 + minutes
                let tenMinuteCycles = totalMinutes / 10
                let _ = totalMinutes % 10
            
            // Calculate frame drops
            let frameDrops = 4 * (totalMinutes - tenMinuteCycles)
            
            // Calculate total frames considering the drop
            return totalMinutes * 60 * 60 +     // Minutes as frames
                   seconds * 60 +               // Seconds as frames
                   frames -                     // Frames 
                   frameDrops                   // Dropped frames
        }
        
                    // For 29.97 drop-frame
            if frInfo.rate.rounded() == 30 {
                // 29.97 drops 2 frames per minute except every 10th minute
                let totalMinutes = hours * 60 + minutes
                let tenMinuteCycles = totalMinutes / 10
                let _ = totalMinutes % 10
            
            // Calculate frame drops
            let frameDrops = 2 * (totalMinutes - tenMinuteCycles)
            
            // Calculate total frames considering the drop
            return totalMinutes * 60 * 30 +     // Minutes as frames
                   seconds * 30 +               // Seconds as frames
                   frames -                     // Frames
                   frameDrops                   // Dropped frames
        }
        
        // Default calculation for other frame rates
        return hours * 3600 * framesPerSecond + 
               minutes * 60 * framesPerSecond + 
               seconds * framesPerSecond + 
               frames
    }
    
    // Convert frames to exact seconds based on the true frame rate
    private func convertFramesToSeconds(totalFrames: Int) -> Double {
        let frInfo = getFrameRateInfo(frameRate)
        
        // For drop-frame formats, apply the NTSC ratio
        if frInfo.isDropFrame {
            switch frInfo.rate.rounded() {
            case 24: // 23.976
                return Double(totalFrames) * (1001.0 / 24000.0)
            case 30: // 29.97
                return Double(totalFrames) * (1001.0 / 30000.0)
            case 60: // 59.94
                return Double(totalFrames) * (1001.0 / 60000.0)
            case 120: // 119.88
                return Double(totalFrames) * (1001.0 / 120000.0)
            default:
                return Double(totalFrames) / frInfo.rate
            }
        }
        
        // For non-drop frame rates
        return Double(totalFrames) / frInfo.rate
    }
    
    // Returns precise frame rate value and drop-frame status
    private func getFrameRateInfo(_ frameRate: TimecodeFrameRate) -> (rate: Double, isDropFrame: Bool) {
        switch frameRate {
        // FCP Supported frame rates
        case .fps23_976:
            return (23.976, true)   // 24 * 1000/1001
        case .fps24:
            return (24.0, false)
        case .fps25:
            return (25.0, false)
        case .fps29_97:
            return (29.97, false)   // Non-drop 29.97
        case .fps29_97d:
            return (29.97, true)    // Drop-frame 29.97
        case .fps30:
            return (30.0, false)
        case .fps30d:
            return (30.0, true)     // Drop-frame 30
        case .fps50:
            return (50.0, false)
        case .fps59_94:
            return (59.94, false)   // Non-drop 59.94
        case .fps59_94d:
            return (59.94, true)    // Drop-frame 59.94
        case .fps60:
            return (60.0, false)
        case .fps60d:
            return (60.0, true)     // Drop-frame 60
        case .fps90:
            return (90.0, false)
        case .fps100:
            return (100.0, false)
        case .fps120:
            return (120.0, false)
        case .fps120d:
            return (120.0, true)    // Drop-frame 120
        default:
            return (30.0, false)    // Default fallback
        }
    }
    
    // Calculate end time for SRT entries with proper millisecond handling
    func calculateEndTime(startTime: String, durationSeconds: Double = 1.0) -> String {
        // Parse the start time
        let parts = startTime.components(separatedBy: ",")
        guard parts.count == 2 else { return startTime }
        
        let timeComponents = parts[0].components(separatedBy: ":")
        guard timeComponents.count == 3,
              let hours = Int(timeComponents[0]),
              let minutes = Int(timeComponents[1]),
              let seconds = Int(timeComponents[2]),
              let milliseconds = Int(parts[1]) else {
            return startTime
        }
        
        // Convert to total milliseconds
        var totalMilliseconds = hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds
        
        // Add duration (in milliseconds)
        totalMilliseconds += Int(durationSeconds * 1000)
        
        // Convert back to hours, minutes, seconds, milliseconds
        let newHours = totalMilliseconds / 3600000
        totalMilliseconds %= 3600000
        let newMinutes = totalMilliseconds / 60000
        totalMilliseconds %= 60000
        let newSeconds = totalMilliseconds / 1000
        let newMilliseconds = totalMilliseconds % 1000
        
        return String(format: "%02d:%02d:%02d,%03d", newHours, newMinutes, newSeconds, newMilliseconds)
    }
}