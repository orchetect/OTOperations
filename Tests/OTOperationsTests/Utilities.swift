//
//  Utilities.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import Foundation
import OTOperations

extension Collection where Element : Equatable {
    
    /// Returns a new array removing duplicate elements, maintaining original array order.
    func removingDuplicates() -> [Element] {
        
        reduce(into: []) { accum, element in
            guard !accum.contains(element) else { return }
            accum.append(element)
        }
        
    }
    
    /// Returns a new array removing identical elements that are sequential (neighboring), maintaining original array order.
    func removingSequentialDuplicates() -> [Element] {
        
        guard self.count > 0 else { return [] }
        
        var out: [Element] = []
        
        var idx = startIndex
        
        while idx < endIndex {
            defer { idx = index(after: idx) }
            guard self[idx] != out.last else { continue }
            out.append(self[idx])
        }
        
        return out
        
    }
    
}

#endif
