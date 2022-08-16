//
//  OperationQueueType.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

public enum OperationQueueType {
    /// Serial (one operation at a time), FIFO (first-in-first-out).
    case serialFIFO
    
    /// Concurrent operations.
    /// Max number of concurrent operations will be automatically determined by the system.
    case concurrentAutomatic
    
    /// Concurrent operations.
    /// Specify the number of max concurrent operations.
    case concurrent(max: Int)
}

#endif
