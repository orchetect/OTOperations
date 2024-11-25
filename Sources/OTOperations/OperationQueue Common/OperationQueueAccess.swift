//
//  OperationQueueAccess.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

public enum OperationQueueAccess {
    /// Immediate access.
    /// Accesses the model in its current state even if queued operations are still in progress.
    case immediate
        
    /// Waits indefinitely until all existing operations on the queue are complete.
    case waitUntilAllOperationsAreFinished
        
    /// Waits until all existing operations on the queue are complete with a timeout period.
    case waitUntilAllOperationsAreFinishedWithTimeout(timeout: TimeInterval)
        
    public func wait(for operationQueue: OperationQueue) {
        switch self {
        case .immediate:
            break // don't wait
        case .waitUntilAllOperationsAreFinished:
            operationQueue.waitUntilAllOperationsAreFinished()
        case let .waitUntilAllOperationsAreFinishedWithTimeout(timeout: timeout):
            operationQueue.waitUntilAllOperationsAreFinished(timeout: timeout)
        }
    }
}

extension OperationQueueAccess: Sendable { }
    
extension OperationQueue {
    /// Provides a convenient interface for conditionally waiting for the operation queue to finish executing.
    public func wait(for access: OperationQueueAccess) {
        access.wait(for: self)
    }
}

#endif
