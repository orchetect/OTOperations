//
//  Operation Extensions.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation

extension Operation {
    
    /// Convenience static constructor for `ClosureOperation`.
    public static func basic(
        weight: OperationQueueProgressWeight = .default(),
        _ mainBlock: @escaping () -> Void
    ) -> ClosureOperation {
        
        let op = ClosureOperation(mainBlock)
        op.progressWeight = weight
        return op
        
    }
    
    /// Convenience static constructor for `InteractiveClosureOperation`.
    public static func interactive(
        weight: OperationQueueProgressWeight = .default(),
        _ mainBlock: @escaping (_ operation: InteractiveClosureOperation) -> Void
    ) -> InteractiveClosureOperation {
        
        let op = InteractiveClosureOperation(mainBlock)
        op.progressWeight = weight
        return op
        
    }
    
    /// Convenience static constructor for `InteractiveAsyncClosureOperation`.
    public static func interactiveAsync(
        on queue: DispatchQueue? = nil,
        weight: OperationQueueProgressWeight = .default(),
        _ mainBlock: @escaping (_ operation: InteractiveAsyncClosureOperation) -> Void
    ) -> InteractiveAsyncClosureOperation {
        
        let op = InteractiveAsyncClosureOperation(on: queue,
                                                  mainBlock)
        op.progressWeight = weight
        return op
        
    }
    
    /// Convenience static constructor for `AtomicBlockOperation`.
    /// Builder pattern can be used to add operations inline.
    public static func atomicBlock<T>(
        type operationQueueType: OperationQueueType,
        initialMutableValue: T,
        weight: OperationQueueProgressWeight = .default(),
        _ setupBlock: ((_ operation: AtomicBlockOperation<T>) -> Void)? = nil
    ) -> AtomicBlockOperation<T> {
        
        let op = AtomicBlockOperation(type: operationQueueType,
                                      initialMutableValue: initialMutableValue)
        op.progressWeight = weight
        
        if let setupBlock = setupBlock {
            op.setSetupBlock(setupBlock)
        }
        
        return op
        
    }
    
}

#endif
