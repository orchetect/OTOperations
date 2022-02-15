//
//  OperationQueueProgressWeight.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

/// OperationQueue progress weight for an individual operation.
public enum OperationQueueProgressWeight: Int64 {
    
    case shortest = 1
    case short = 10
    case mediumShort = 50
    case medium = 100
    case mediumLong = 200
    case long = 500
    case veryLong = 10_000
    case longest = 100_000
    
    /// Return default of `.medium`.
    public static func `default`() -> Self {
        
        .medium
        
    }
    
}

#endif
