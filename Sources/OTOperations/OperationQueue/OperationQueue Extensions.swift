//
//  OperationQueue Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

extension OperationQueue {
    /// Blocks the current thread until all the receiver’s queued and executing operations finish
    /// executing. Same as calling `waitUntilAllOperationsAreFinished()` but offers a timeout duration.
    @discardableResult
    public func waitUntilAllOperationsAreFinished(
        timeout: TimeInterval? = nil
    ) -> DispatchTimeoutResult {
        // no timeout
        
        guard let timeout = timeout else {
            self.waitUntilAllOperationsAreFinished()
            return .success
        }
        
        // with timeout
        
        let g = DispatchGroup()
        g.enter()
        
        DispatchQueue.global().async {
            self.waitUntilAllOperationsAreFinished()
            g.leave()
        }
        
        return g.wait(timeout: .now() + timeout)
    }
}

#endif
