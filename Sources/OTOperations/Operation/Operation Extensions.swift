//
//  Operation Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

extension Operation {
    
    /// Convenience static constructor for `ClosureOperation`.
    public static func basic(
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default(),
        _ mainBlock: @escaping () -> Void
    ) -> ClosureOperation {
        
        ClosureOperation(label: label,
                         weight: weight,
                         mainBlock)
        
    }
    
    /// Convenience static constructor for `InteractiveClosureOperation`.
    public static func interactive(
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default(),
        _ mainBlock: @escaping (_ operation: InteractiveClosureOperation) -> Void
    ) -> InteractiveClosureOperation {
        
        InteractiveClosureOperation(label: label,
                                    weight: weight,
                                    mainBlock)
        
    }
    
    /// Convenience static constructor for `InteractiveAsyncClosureOperation`.
    public static func interactiveAsync(
        on queue: DispatchQueue? = nil,
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default(),
        _ mainBlock: @escaping (_ operation: InteractiveAsyncClosureOperation) -> Void
    ) -> InteractiveAsyncClosureOperation {
        
        InteractiveAsyncClosureOperation(on: queue,
                                         label: label,
                                         weight: weight,
                                         mainBlock)
        
    }
    
    /// Convenience static constructor for `AtomicBlockOperation`.
    /// Builder pattern can be used to add operations inline.
    public static func atomicBlock<T>(
        type operationQueueType: OperationQueueType,
        initialMutableValue: T,
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default(),
        _ setupBlock: ((_ operation: AtomicBlockOperation<T>) -> Void)? = nil
    ) -> AtomicBlockOperation<T> {
        
        let op = AtomicBlockOperation(type: operationQueueType,
                                      label: label,
                                      weight: weight,
                                      initialMutableValue: initialMutableValue)
        
        if let setupBlock = setupBlock {
            op.setSetupBlock(setupBlock)
        }
        
        return op
        
    }
    
}

#endif
