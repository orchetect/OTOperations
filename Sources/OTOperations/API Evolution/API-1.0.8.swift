//
//  API-1.0.8.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

// MARK: API Changes in 1.0.8

#if canImport(Foundation)

extension AtomicBlockOperation {
    @available(*, deprecated, renamed: "withValue")
    public final func mutateValue(_ block: (inout T) -> Void) {
        withValue(block)
    }
}

extension AtomicOperationQueue {
    @available(*, deprecated, renamed: "withValue")
    public func mutateValue(_ block: (inout T) -> Void) {
        withValue(block)
    }
}

extension AtomicOperationQueue.VariableAccess {
    @available(*, deprecated, renamed: "withValue")
    public func mutate(_ block: (_ value: inout T) -> Void) {
        withValue(block)
    }
}

#endif
