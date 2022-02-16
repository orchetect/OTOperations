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
    ///   - label: nested operation labels
    ///   - message: displayable string describing the current operation
    case inProgress(fractionCompleted: Double,
                    label: String? = nil,
                    description: String)
    
    /// Operation queue is paused.
    /// There may or may not be operations in the queue.
    case paused
    
}

extension OperationQueueStatus: CustomStringConvertible {
    
    public var description: String {
        
        switch self {
        case .idle:
            return "idle"
            
        case .inProgress(let fractionCompleted,
                         let label,
                         let description):
            let labelStr = label == nil ? "" : "[\(label!)] "
            return "\(fractionCompleted) \(labelStr)\"\(description)\""
            
        case .paused:
            return "paused"
        }
        
    }
    
}

// MARK: - Convenience Methods

extension OperationQueueStatus {
    
    /// Returns `true` if case is `.inProgress`.
    public var isInProgress: Bool {
        
        if case .inProgress = self { return true }
        else { return false }
        
    }
    
}

#endif
