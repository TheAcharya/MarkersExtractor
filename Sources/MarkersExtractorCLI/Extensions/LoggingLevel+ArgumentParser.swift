//
//  LoggingLevel+ArgumentParser.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Logging

// Note: Use of `@retroactive` is safe here since `Logger.Level` is not likely to ever be
// conformed to ExpressibleByArgument in swift-log.
extension Logger.Level: @retroactive ExpressibleByArgument { }
