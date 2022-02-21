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
        guard let nsSet = getChildren as? NSSet else { return [] }
        let mappedChildren = nsSet.compactMap { $0 as? Progress }
        let mappedSet = Set(mappedChildren)
        return mappedSet
        
    }
    
    /// Removes any child `LabelProgress` references manually and decouples them.
    internal func purgeLabelProgressChildren() {
        
        guard let children = value(forKeyPath: "children") as? NSMutableSet,
              children.count > 0
        else { return }
        
        children
            .allObjects
            .compactMap { $0 as? LabelProgress }
            .forEach {
                $0.setValue(nil, forKeyPath: "parent")
                children.remove($0)
            }
        
    }
    
}

#endif
