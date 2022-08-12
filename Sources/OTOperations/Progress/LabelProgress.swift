//
//  LabelProgress.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation) && canImport(CoreFoundation)

import Foundation
import CoreFoundation
import OTAtomics

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
            _label
        }
        set {
            let oldValue = _label
            
            if newValue?.isEmpty == true {
                _label = nil
            } else {
                _label = newValue
            }
            
            generateLabels()
            
            if newValue != oldValue {
                notifyParentToUpdateChildren()
            }
        }
    }
    
    @OTAtomicsThreadSafe
    private var _label: String?
    
    /// Custom label (user-readable description) that combines the current instance's label with the labels of direct children only.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    @OTAtomicsThreadSafe
    public private(set) var combinedLabel: String?
    
    private func generateCombinedLabel() {
        var out = label
        let getChildLabels = childLabels.joined(separator: ", ")
        if !getChildLabels.isEmpty {
            out = out == nil ? getChildLabels : out! + " - " + getChildLabels
        }
        combinedLabel = out
    }
    
    /// Custom label (user-readable description) that combines the current instance's label with the labels of all nested children.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    @OTAtomicsThreadSafe
    public private(set) var deepLabel: String? = nil
    
    private func generateDeepLabel() {
        var out = label
        let getChildLabels = deepLabels.joined(separator: ", ")
        if !getChildLabels.isEmpty {
            out = out == nil ? getChildLabels : out! + " - " + getChildLabels
        }
        deepLabel = out
    }
    
    /// Returns an array of the labels of direct children only (not nested children).
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    @OTAtomicsThreadSafe
    public private(set) var childLabels: [String] = []
    
    @OTAtomicsThreadSafe
    private var combinedLabels: [String] = []
    
    /// Returns an array of the labels of all nested children.
    ///
    /// - Note: Child `Progress` objects are stored internally as an `NSSet` which means their order will be random and may change. Their ordering will be stable for their lifecycle however.
    @OTAtomicsThreadSafe
    public private(set) var deepLabels: [String] = []
    
    // MARK: - Helpers
    
    /// Introspects all 1st-generation child progress objects and caches their labels.
    internal func updateChildLabelsAndNotifyParent(incompleteOnly: Bool = true) {
        let children = labelProgressChildren
        
        // remove duplicates while maintaining NSSet order
        let labels: [String] = children
            .compactMap { element -> String? in
                if incompleteOnly, (element.isFinished || element.isCancelled) {
                    return nil
                }
                return element.label
            }
            .removingDuplicatesSorted()
        
        childLabels = labels
        
        // remove duplicates while maintaining NSSet order
        let combinedLabels: [String] = children
            .compactMap { element -> String? in
                if incompleteOnly, (element.isFinished || element.isCancelled) {
                    return nil
                }
                return element.deepLabel
            }
            .removingDuplicatesSorted()
        
        deepLabels = combinedLabels
        
        generateLabels()
        notifyParentToUpdateChildren()
    }
    
    private func generateLabels() {
        generateCombinedLabel()
        generateDeepLabel()
    }
    
    private func notifyParentToUpdateChildren() {
        labelProgressParent?.updateChildLabelsAndNotifyParent()
    }
    
    // MARK: - Inits
    
    public init() {
        super.init(
            parent: nil,
            userInfo: nil
        )
    }
    
    public init(totalUnitCount unitCount: Int64) {
        super.init(
            parent: nil,
            userInfo: nil
        )
        totalUnitCount = unitCount
    }
    
    public init(
        totalUnitCount unitCount: Int64,
        label: String
    ) {
        super.init(
            parent: nil,
            userInfo: nil
        )
        totalUnitCount = unitCount
        self.label = label
    }
    
    // sadly there is no way to make the compiler happy when trying to do this...
    //
    // public convenience init(totalUnitCount unitCount: Int64,
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
    // }
    
    public init(
        parent parentProgressOrNil: Progress?,
        userInfo userInfoOrNil: [ProgressUserInfoKey: Any]? = nil,
        label: String
    ) {
        super.init(
            parent: parentProgressOrNil,
            userInfo: userInfoOrNil
        )
        self.label = label
        notifyParentToUpdateChildren()
    }
    
    // MARK: - Class Overrides
    
    override public func addChild(
        _ child: Progress,
        withPendingUnitCount inUnitCount: Int64
    ) {
        super.addChild(
            child,
            withPendingUnitCount: inUnitCount
        )
        updateChildLabelsAndNotifyParent()
    }
    
    deinit {
        // manually nil the label
        _label = nil
        combinedLabel = nil
        deepLabel = nil
        
        // notify the parent to update
        if let parentProgress = labelProgressParent {
            DispatchQueue.global().async {
                parentProgress.notifyParentToUpdateChildren()
            }
        }
    }
}

#endif
