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
        
        autoreleasepool {
            // keyPath "_parent" also works
            let getParent = value(forKeyPath: "parent")
            let typedParent = getParent as? Progress
            return typedParent
        }
        
    }
    
    /// Returns all child `Progress` instances that are attached.
    @_disfavoredOverload
    internal var children: Set<Progress> {
        
        autoreleasepool {
            // keyPath "_children" also works
            let getChildren = value(forKeyPath: "children")
            guard let nsSet = getChildren as? NSSet else { return [] }
            let mappedChildren = nsSet.compactMap { $0 as? Progress }
            let mappedSet = Set(mappedChildren)
            return mappedSet
        }
        
    }
    
    /// Removes any child `Progress` references manually and decouples them.
    /// Returns number of children purged.
    @_disfavoredOverload @discardableResult
    internal func purgeChildren() -> Int {
        
        var purgedCount = 0
        
        autoreleasepool {
            guard let getValue = value(forKeyPath: "children"),
                  let nsSet = getValue as? NSMutableSet
            else { return }
            
            let children = nsSet.compactMap { $0 as? Progress }
            
            guard children.count > 0
            else { return }
            
            purgedCount = children.count
            
            children
                .forEach {
                    // 'complete' the child before removing it or it may stay resident in memory
                    $0.completedUnitCount = $0.totalUnitCount
                    
                    // remove parent ref from child
                    $0.setValue(nil, forKeyPath: "parent")
                    
                    // remove child ref from parent
                    nsSet.remove($0)
                }
        }
        
        return purgedCount
        
    }
    
}

extension LabelProgress {

    /// Removes any child `LabelProgress` references manually and decouples them.
    @_disfavoredOverload @discardableResult
    internal func purgeLabelProgressChildren() -> Int {
        
        var purgedCount = 0
        
        autoreleasepool {
            guard let getValue = value(forKeyPath: "children"),
                  let nsSet = getValue as? NSMutableSet
            else { return }
            
            let typedChildren = nsSet.compactMap { $0 as? LabelProgress }
            
            guard typedChildren.count > 0
            else { return }
            
            purgedCount = typedChildren.count
            
            typedChildren
                .forEach {
                    // 'complete' the child before removing it or it may stay resident in memory
                    $0.completedUnitCount = $0.totalUnitCount
                    
                    // remove parent ref from child
                    $0.setValue(nil, forKeyPath: "parent")
                    
                    // remove child ref from parent
                    nsSet.remove($0)
                }
        }
        
        return purgedCount
        
    }
    
}

#endif
