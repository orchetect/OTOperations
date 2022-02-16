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
        let getParent = value(forKeyPath: "parent")
        let typedParent = getParent as? Progress
        return typedParent
        
    }
    
    /// Returns all child `Progress` instances that are attached.
    @_disfavoredOverload
    internal var children: Set<Progress> {
        
        // keyPath "_children" also works
        let getChildren = value(forKeyPath: "children")
        let typedChildren = getChildren as? Set<Progress>
        return typedChildren ?? []
        
    }
    
}

#endif
