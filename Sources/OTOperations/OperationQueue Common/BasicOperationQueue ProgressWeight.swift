//
//  BasicOperationQueue ProgressWeight.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

extension BasicOperationQueue {
    /// Progress weight for an individual operation.
    public enum ProgressWeight: Int64 {
        case shortest = 1
        case short = 10
        case mediumShort = 50
        case medium = 100
        case mediumLong = 200
        case long = 500
        case veryLong = 10000
        case longest = 100_000
        
        /// Return default of `.medium`.
        public static func `default`() -> Self {
            .medium
        }
    }
}

#endif
