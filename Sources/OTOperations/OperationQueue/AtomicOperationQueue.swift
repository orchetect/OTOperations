//
//  AtomicOperationQueue.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation
import OTAtomics

/// An `OperationQueue` subclass that passes shared thread-safe variable into operation closures.
/// Concurrency type can be specified.
/// 
/// - note: Inherits from `BasicOperationQueue`.
open class AtomicOperationQueue<T>: BasicOperationQueue {
    
    /// The thread-safe shared mutable value that all operation blocks operate upon.
    @OTAtomicsThreadSafe public final var sharedMutableValue: T
    
    // MARK: - Init
    
    public init(
        type operationQueueType: OperationQueueType = .concurrentAutomatic,
        qualityOfService: QualityOfService? = nil,
        initiallySuspended: Bool = false,
        resetProgressWhenFinished: Bool = false,
        initialMutableValue: T,
        label: String? = nil,
        statusHandler: BasicOperationQueue.StatusHandler? = nil
    ) {
        
        self.sharedMutableValue = initialMutableValue
        
        super.init(type: operationQueueType,
                   label: label,
                   resetProgressWhenFinished: resetProgressWhenFinished,
                   statusHandler: statusHandler)
        
        if let qualityOfService = qualityOfService {
            self.qualityOfService = qualityOfService
        }
        
        if initiallySuspended {
            isSuspended = true
        }
        
    }
    
    // MARK: - Shared Mutable Value Methods
    
    /// Add an operation block operating on the shared mutable value.
    ///
    /// - returns: The new operation.
    @discardableResult
    public final func addOperation(
        dependencies: [Operation] = [],
        weight: ProgressWeight = .default(),
        _ block: @escaping (_ atomicValue: VariableAccess) -> Void
    ) -> ClosureOperation {
        
        let op = createOperation(weight: weight, block)
        dependencies.forEach { op.addDependency($0) }
        addOperation(op)
        return op
            
    }
    
    /// Add an operation block operating on the shared mutable value.
    /// `operation.mainShouldAbort()` can be periodically called and then early return if the operation may take more than a few seconds.
    ///
    /// - returns: The new operation.
    @discardableResult
    public final func addInteractiveOperation(
        dependencies: [Operation] = [],
        weight: ProgressWeight = .default(),
        _ block: @escaping (_ operation: InteractiveClosureOperation,
                            _ atomicValue: VariableAccess) -> Void
    ) -> InteractiveClosureOperation {
        
        let op = createInteractiveOperation(weight: weight, block)
        dependencies.forEach { op.addDependency($0) }
        addOperation(op)
        return op
        
    }
    
    /// Add a barrier block operation to the operation queue.
    ///
    /// Invoked after all currently enqueued operations have finished. Operations you add after the barrier block don’t start until the block has completed.
    @available(macOS 10.15, iOS 13.0, tvOS 13, watchOS 6, *)
    public final func addBarrierBlock(
        _ barrier: @escaping (_ atomicValue: VariableAccess) -> Void
    ) {
        
        addBarrierBlock { [weak self] in
            guard let self = self else { return }
            let varAccess = VariableAccess(operationQueue: self)
            barrier(varAccess)
        }
        
    }
    
    // MARK: - Factory Methods
    
    /// Internal for debugging:
    /// Create an operation block operating on the shared mutable value.
    internal final func createOperation(
        weight: ProgressWeight = .default(),
        _ block: @escaping (_ atomicValue: VariableAccess) -> Void
    ) -> ClosureOperation {
        
        let op = ClosureOperation { [weak self] in
            guard let self = self else { return }
            let varAccess = VariableAccess(operationQueue: self)
            block(varAccess)
        }
        op.progressWeight = weight
        return op
        
    }
    
    /// Internal for debugging:
    /// Create an operation block operating on the shared mutable value.
    /// `operation.mainShouldAbort()` can be periodically called and then early return if the operation may take more than a few seconds.
    internal final func createInteractiveOperation(
        weight: ProgressWeight = .default(),
        _ block: @escaping (_ operation: InteractiveClosureOperation,
                            _ atomicValue: VariableAccess) -> Void
    ) -> InteractiveClosureOperation {
        
        let op = InteractiveClosureOperation { [weak self] operation in
            guard let self = self else { return }
            let varAccess = VariableAccess(operationQueue: self)
            block(operation, varAccess)
        }
        op.progressWeight = weight
        return op
        
    }
    
    /// Mutate the shared atomic variable in a closure.
    public func mutateValue(_ block: (inout T) -> Void) {
        
        block(&sharedMutableValue)
        
    }
    
}

#endif
