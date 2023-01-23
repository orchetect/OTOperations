//
//  AtomicOperationQueue VariableAccess.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

extension AtomicOperationQueue {
    /// Proxy object providing mutation access to a thread-safe atomic variable.
    public class VariableAccess {
        private /* weak */ var operationQueue: AtomicOperationQueue<T>
        
        internal init(operationQueue: AtomicOperationQueue<T>) {
            self.operationQueue = operationQueue
        }
        
        /// Provides a closure to mutate the shared atomic variable and optionally return a value.
        /// 
        /// - Warning: Perform as little logic as possible and only use this closure to get or set the variable.
        /// Failure to do so may result in deadlocks in complex multi-threaded applications.
        @discardableResult
        public func withValue<U>(_ block: (_ value: inout T) throws -> U) rethrows -> U {
            try block(&operationQueue.sharedMutableValue)
        }
    }
}

#endif
