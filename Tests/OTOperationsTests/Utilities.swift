//
//  Utilities.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import Foundation
import OTOperations

extension Collection where Element: Equatable {
    /// Returns a new array removing identical elements that are sequential (neighboring), maintaining original array order.
    @_disfavoredOverload
    func removingSequentialDuplicates() -> [Element] {
        guard !isEmpty else { return [] }
        
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
