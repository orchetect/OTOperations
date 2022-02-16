//
//  Progress Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

extension Progress {
    
    /// Returns the parent `Progress` instance, if one is attached.
    @_disfavoredOverload
    internal var parent: Progress? {
        
        // keyPath "_parent" also works
        value(forKeyPath: "parent") as? Progress
        
    }
    
    /// Returns all child `Progress` instances that are attached.
    @_disfavoredOverload
    internal var children: Set<Progress> {
        
        // keyPath "_children" also works
        value(forKeyPath: "children") as? Set<Progress> ?? []
        
    }
    
}

#endif
