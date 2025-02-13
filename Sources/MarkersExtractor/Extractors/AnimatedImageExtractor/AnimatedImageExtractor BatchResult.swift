//
//  AnimatedImageExtractor BatchResult.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension AnimatedImageExtractor {
    actor BatchResult {
        var errors: [(descriptor: ImageDescriptor, error: AnimatedImageExtractorError)] = []
        var isBatchFinished = false
        
        init(errors: [(descriptor: ImageDescriptor, error: AnimatedImageExtractorError)] = []) {
            self.errors = errors
        }
    }
}

// MARK: - Methods

extension AnimatedImageExtractor.BatchResult {
    func addError(for descriptor: ImageDescriptor, _ error: AnimatedImageExtractorError) {
        errors.append((descriptor: descriptor, error: error))
    }
    
    func setFinished() {
        isBatchFinished = true
    }
}
