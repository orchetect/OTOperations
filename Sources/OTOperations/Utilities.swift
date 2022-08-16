//
//  Utilities.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

extension Collection where Element: Equatable {
    /// Returns a new array removing duplicate elements, maintaining original array order.
    @_disfavoredOverload
    internal func removingDuplicates() -> [Element] {
        reduce(into: []) { accum, element in
            guard !accum.contains(element) else { return }
            accum.append(element)
        }
    }
}

extension Collection where Element: Hashable,
Element: Comparable {
    /// Returns a new array removing duplicate elements, sorting results by default sort method.
    @_disfavoredOverload
    internal func removingDuplicatesSorted() -> [Element] {
        Set(self).sorted()
    }
}

#endif
