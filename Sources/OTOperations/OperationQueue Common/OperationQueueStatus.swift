//
//  OperationQueueStatus.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

/// Operation queue status.
/// Used by `BasicOperationQueue` and its subclasses.
public enum OperationQueueStatus: Equatable, Hashable {
    
    /// Operation queue is empty. No operations are executing.
    case idle
    
    /// Operation queue is executing one or more operations.
    /// - Parameters:
    ///   - fractionCompleted: progress between 0.0...1.0
    ///   - message: displayable string describing the current operation
    case inProgress(fractionCompleted: Double, message: String)
    
    /// Operation queue is paused.
    /// There may or may not be operations in the queue.
    case paused
    
}

extension OperationQueueStatus: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .idle:
            return "idle"
            
        case .inProgress(let fractionCompleted, let message):
            return "\(fractionCompleted) \"\(message)\""
            
        case .paused:
            return "paused"
        }
        
    }
    
}

#endif
