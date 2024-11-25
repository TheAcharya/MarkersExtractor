//
//  Logging.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging

@globalActor final actor LogFactory {
    public static let shared = LogFactory()
    
    fileprivate var consoleLogHandler: LogHandler?
    fileprivate var fileLogHandler: LogHandler?
    
    public init() { }
    
    public func fileAndConsoleLogFactory(label: String, logLevel: Logger.Level?, logFile: URL?) -> LogHandler {
        guard let logLevel else {
            return SwiftLogNoOpLogHandler()
        }
        
        var logHandlers: [LogHandler] = [
            consoleLogFactory(label: label, logLevel: logLevel)
        ]
        
        if let logFile,
           let fileLogger = fileLogFactory(label: label, logLevel: logLevel, logFile: logFile)
        {
            logHandlers.insert(fileLogger, at: 0)
        }
        
        return MultiplexLogHandler(logHandlers)
    }
    
    public func consoleLogFactory(label: String, logLevel: Logger.Level) -> LogHandler {
        if let consoleLogHandler { return consoleLogHandler }
        
        var handler = ConsoleLogHandler(label: label)
        handler.logLevel = logLevel
        
        consoleLogHandler = handler
        
        return handler
    }
    
    public func fileLogFactory(label: String, logLevel: Logger.Level, logFile: URL?) -> LogHandler? {
        guard let logFile else { return nil }
        
        if let fileLogHandler { return fileLogHandler }
        
        do {
            // ensure the folder structure exists prior to attempting to create/write to the file
            // otherwise this will throw an error and the file won't be created on disk.
            
            let logFileParentPath = logFile.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: logFileParentPath, withIntermediateDirectories: true)
            
            var handler = try FileLogHandler(label: label, localFile: logFile)
            handler.logLevel = logLevel
            
            fileLogHandler = handler
            
            return handler
        } catch {
            print(
                "Cannot write to log file \(logFile.lastPathComponent.quoted):"
                + " \(error.localizedDescription)"
            )
            return nil
        }
    }
}
