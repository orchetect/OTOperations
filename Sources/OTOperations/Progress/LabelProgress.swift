//
//  LabelProgress.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation) && canImport(CoreFoundation)

import Foundation
import CoreFoundation

/// A `Progress` subclass that supports a custom label and automatically aggregates labels from child progress objects.
public class LabelProgress: Progress {
    
    // MARK: - Refs
    
    private var labelProgressParent: LabelProgress? {
        
        parent as? LabelProgress
        
    }
    
    // MARK: - Label Properties
    
    /// Custom label (user-readable description) for this progress instance (not including children).
    /// Set this property to set this progress instance's label, or set to nil to remove the label if one was set.
    public var label: String? {
        get {
            userInfo[.label] as? String
        }
        set {
            let oldValue = userInfo[.label] as? String
            
            if newValue?.isEmpty == true {
                setUserInfoObject(nil, forKey: .label)
            } else {
                setUserInfoObject(newValue, forKey: .label)
            }
            updateUserInfoWithCombinedLabel()
            
            if newValue != oldValue {
                notifyParentToUpdateChildren()
            }
        }
    }
    
    /// Custom label (user-readable description) that combines the current instance's label with the labels of direct children only.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    public var combinedLabel: String? {
        
        var out = label
        let getChildLabels = childLabels.joined(separator: ", ")
        if !getChildLabels.isEmpty {
            out = out == nil ? getChildLabels : out! + " - " + getChildLabels
        }
        return out
        
    }
    
    /// Custom label (user-readable description) that combines the current instance's label with the labels of all nested children.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    public var deepLabel: String? {
        
        var out = label
        let getChildLabels = deepLabels.joined(separator: ", ")
        if !getChildLabels.isEmpty {
            out = out == nil ? getChildLabels : out! + " - " + getChildLabels
        }
        return out
        
    }
    
    /// Returns an array of the labels of direct children only (not nested children).
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    public var childLabels: [String] {
        
        userInfo[.childLabels] as? [String] ?? []
        
    }
    
    /// Returns an array of the labels of all nested children.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    public var deepLabels: [String] {
        
        userInfo[.deepLabels] as? [String] ?? []
        
    }
    
    // MARK: - Helpers
    
    /// Introspects all 1st-generation child progress objects and caches their labels in this progress instance's `userInfo` dictionary.
    private func updateUserInfoWithChildLabelsAndNotifyParent(incompleteOnly: Bool = true) {
        
        let children = self.children as? Set<LabelProgress> ?? []
        
        autoreleasepool {
            // remove duplicates while maintaining NSSet order
            let labels: [String] = children
                .compactMap { element -> String? in
                    if incompleteOnly, (element.isFinished || element.isCancelled) {
                       return nil
                    }
                    return element.userInfo[.label] as? String
                }
                .reduce(into: []) { accum, element in
                    guard !accum.contains(element) else { return }
                    accum.append(element)
                }
                .sorted()
            
            setUserInfoObject(labels, forKey: .childLabels)
            
            // remove duplicates while maintaining NSSet order
            let combinedLabels: [String] = children
                .compactMap { element -> String? in
                    if incompleteOnly, (element.isFinished || element.isCancelled) {
                        return nil
                    }
                    return element.userInfo[.combinedLabel] as? String
                }
                .reduce(into: []) { accum, element in
                    guard !accum.contains(element) else { return }
                    accum.append(element)
                }
                .sorted()
            
            setUserInfoObject(combinedLabels, forKey: .deepLabels)
        }
        
        updateUserInfoWithCombinedLabel()
        
        notifyParentToUpdateChildren()
        
    }
    
    private func updateUserInfoWithCombinedLabel() {
        
        setUserInfoObject(deepLabel, forKey: .combinedLabel)
        
    }
    
    private func notifyParentToUpdateChildren() {
        
        labelProgressParent?.updateUserInfoWithChildLabelsAndNotifyParent()
        
    }
    
    // MARK: - Inits
    
    public init() {
        
        super.init(parent: nil,
                   userInfo: nil)
        
    }
    
    public init(totalUnitCount unitCount: Int64) {
        
        super.init(parent: nil,
                   userInfo: nil)
        self.totalUnitCount = unitCount
        
    }
    
    public init(totalUnitCount unitCount: Int64,
                label: String) {

        super.init(parent: nil,
                   userInfo: nil)
        self.totalUnitCount = unitCount
        self.label = label
        
    }
    
    // sadly there is no way to make the compiler happy when trying to do this...
    //
    //public convenience init(totalUnitCount unitCount: Int64,
    //                        parent: Progress,
    //                        pendingUnitCount portionOfParentTotalUnitCount: Int64,
    //                        label: String) {
    //
    //    self.init(totalUnitCount: unitCount,
    //               parent: parent,
    //               pendingUnitCount: portionOfParentTotalUnitCount)
    //    self.label = label
    //    notifyParentToUpdateChildren() // needed?
    //
    //}
    
    public init(parent parentProgressOrNil: Progress?,
                userInfo userInfoOrNil: [ProgressUserInfoKey : Any]? = nil,
                label: String) {
        
        super.init(parent: parentProgressOrNil,
                   userInfo: userInfoOrNil)
        self.label = label
        notifyParentToUpdateChildren()
        
    }
    
    // MARK: - Class Overrides
    
    public override func addChild(_ child: Progress,
                                  withPendingUnitCount inUnitCount: Int64) {
        
        super.addChild(child,
                       withPendingUnitCount: inUnitCount)
        updateUserInfoWithChildLabelsAndNotifyParent()
        
    }
    
    deinit {
        
        // manually nil the label
        setUserInfoObject(nil, forKey: .label)
        
        // notify the parent to update
        if let parentProgress = labelProgressParent {
            DispatchQueue.global().async {
                parentProgress.updateUserInfoWithChildLabelsAndNotifyParent()
            }
        }
        
    }
    
}

#endif
