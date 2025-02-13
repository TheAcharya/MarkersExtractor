//
//  StillImageBatchExtractor BatchResult.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

extension StillImageBatchExtractor {
    actor BatchResult: Sendable {
        var errors: [(descriptor: ImageDescriptor, error: StillImageBatchExtractorError)] = []
        var isBatchFinished = false
        
        init(errors: [(descriptor: ImageDescriptor, error: StillImageBatchExtractorError)] = []) {
            self.errors = errors
        }
    }
}

// MARK: - Methods

extension StillImageBatchExtractor.BatchResult {
    func addError(
        for descriptor: ImageDescriptor,
        _ error: StillImageBatchExtractorError
    ) {
        errors.append((descriptor: descriptor, error: error))
    }
    
    func setFinished() {
        isBatchFinished = true
    }
}
