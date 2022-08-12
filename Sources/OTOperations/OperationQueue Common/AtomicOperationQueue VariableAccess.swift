//
//  AtomicOperationQueue VariableAccess.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

extension AtomicOperationQueue {
    /// Proxy object providing mutation access to a thread-safe atomic variable.
    public class VariableAccess {
        private weak var operationQueue: AtomicOperationQueue<T>?
        
        internal init(operationQueue: AtomicOperationQueue<T>) {
            self.operationQueue = operationQueue
        }
        
        /// Mutate the atomic variable in a closure.
        /// Warning: Perform as little logic as possible and only use this closure to get or set the variable. Failure to do so may result in deadlocks in complex multi-threaded applications.
        public func mutate(_ block: (_ value: inout T) -> Void) {
            guard let operationQueue = operationQueue else { return }
            block(&operationQueue.sharedMutableValue)
        }
    }
}

#endif
