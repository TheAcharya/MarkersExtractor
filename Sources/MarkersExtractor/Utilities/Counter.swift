//
//  Counter.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

/// Sendable counter object.
actor Counter {
    private(set) var count: Int
    private let onUpdate: ((_ count: Int) -> Void)?
    
    init(count: Int, onUpdate: ((_ count: Int) -> Void)? = nil) {
        self.count = count
        self.onUpdate = onUpdate
    }
}

// MARK: - Methods

extension Counter {
    func increment() {
        setCount(count + 1)
    }
    
    func decrement() {
        setCount(count - 1)
    }
    
    func setCount(_ count: Int) {
        self.count = count
        onUpdate?(count)
    }
}
