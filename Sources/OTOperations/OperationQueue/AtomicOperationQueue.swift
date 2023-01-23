//
//  AtomicOperationQueue.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
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
        sharedMutableValue = initialMutableValue
        
        super.init(
            type: operationQueueType,
            label: label,
            resetProgressWhenFinished: resetProgressWhenFinished,
            statusHandler: statusHandler
        )
        
        if let qualityOfService = qualityOfService {
            self.qualityOfService = qualityOfService
        }
        
        if initiallySuspended {
            isSuspended = true
        }
    }
    
    // MARK: - Shared Mutable Value Methods
    
    // NOTE: when updating this inline docs block, copy it over to
    // `class ClosureOperation`
    /// A synchronous `Operation` subclass that provides essential boilerplate for building an operation and supplies a closure as a convenience when further subclassing is not necessary.
    ///
    /// This operation is synchronous. If the operation is run without being inserted into an `OperationQueue`, when you call the `start()` method the operation executes immediately in the current thread. By the time the `start()` method returns control, the operation is complete.
    ///
    /// **Usage**
    ///
    /// No special method calls are required in the main block.
    ///
    /// This closure is not cancellable once it is started, and does not offer a reference to update progress information. If you want to allow cancellation (early return partway through operation execution) or progress updating, use `InteractiveClosureOperation` instead.
    ///
    ///     let op = ClosureOperation {
    ///         // ... do some work ...
    ///
    ///         // operation completes & cleans up automatically
    ///         // after closure finishes
    ///     }
    ///
    /// Add the operation to an `OperationQueue` or start it manually if not being inserted into an OperationQueue.
    ///
    ///     // if inserting into an OperationQueue:
    ///     let opQueue = OperationQueue()
    ///     opQueue.addOperation(op)
    ///
    ///     // if not inserting into an OperationQueue:
    ///     op.start()
    ///
    /// - important: This object is not intended to be subclassed. Rather, it is a simple convenience wrapper when a closure is needed to be wrapped in an `Operation` for when you require a reference to the operation which would not otherwise be available if `.addOperation{}` was called directly on an `OperationQueue`.
    ///
    /// - note: Inherits from `BasicOperation`.
    ///
    /// - returns: The new operation.
    @discardableResult
    public final func addOperation(
        label: String? = nil,
        weight: ProgressWeight = .default(),
        dependencies: [Operation] = [],
        _ block: @escaping (_ atomicValue: VariableAccess) -> Void
    ) -> ClosureOperation {
        let op = createOperation(
            label: label,
            weight: weight,
            block
        )
        dependencies.forEach { op.addDependency($0) }
        addOperation(op)
        return op
    }
    
    // NOTE: when updating this inline docs block, copy it over to
    // `class InteractiveClosureOperation`
    /// A synchronous `Operation` subclass that provides essential boilerplate for building an operation and supplies a closure as a convenience when further subclassing is not necessary.
    ///
    /// This operation is synchronous. If the operation is run without being inserted into an `OperationQueue`, when you call the `start()` method the operation executes immediately in the current thread. By the time the `start()` method returns control, the operation is complete.
    ///
    /// **Usage**
    ///
    /// No specific calls are required to be made within the main block, however it is best practise to periodically check if the operation is cancelled and return early if the operation may take more than a few seconds.
    ///
    /// If progress information is available, set `operation.progress.totalUnitCount` and periodically update `operation.progress.completedUnitCount` through the operation. Cleanup will automatically finish the progress and set it to 100% once the block finishes.
    ///
    ///     let op = InteractiveClosureOperation { operation in
    ///         // optionally: set progress info
    ///         operation.progress.totalUnitCount = 100
    ///
    ///         // ... do some work ...
    ///
    ///         // optionally: update progress periodically
    ///         operation.progress.completedUnitCount = 50
    ///
    ///         // optionally: if the operation takes more
    ///         // than a few seconds on average,
    ///         // it's good practise to periodically
    ///         // check if operation is cancelled and return
    ///         if operation.mainShouldAbort() { return }
    ///
    ///         // ... do some work ...
    ///     }
    ///
    /// Add the operation to an `OperationQueue` or start it manually if not being inserted into an OperationQueue.
    ///
    ///     // if inserting into an OperationQueue:
    ///     let opQueue = OperationQueue()
    ///     opQueue.addOperation(op)
    ///
    ///     // if not inserting into an OperationQueue:
    ///     op.start()
    ///
    /// - important: This object is not intended to be subclassed. Rather, it is a simple convenience wrapper when a closure is needed to be wrapped in an `Operation` for when you require a reference to the operation which would not otherwise be available if `.addOperation{}` was called directly on an `OperationQueue`.
    ///
    /// - note: Inherits from `BasicOperation`.
    ///
    /// - returns: The new operation.
    @discardableResult
    public final func addInteractiveOperation(
        label: String? = nil,
        weight: ProgressWeight = .default(),
        dependencies: [Operation] = [],
        _ block: @escaping (
            _ operation: InteractiveClosureOperation,
            _ atomicValue: VariableAccess
        ) -> Void
    ) -> InteractiveClosureOperation {
        let op = createInteractiveOperation(
            label: label,
            weight: weight,
            block
        )
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
        label: String? = nil,
        weight: ProgressWeight = .default(),
        _ block: @escaping (_ atomicValue: VariableAccess) -> Void
    ) -> ClosureOperation {
        ClosureOperation(
            label: label,
            weight: weight
        ) { [weak self] in
            guard let self = self else { return }
            let varAccess = VariableAccess(operationQueue: self)
            block(varAccess)
        }
    }
    
    /// Internal for debugging:
    /// Create an operation block operating on the shared mutable value.
    /// `operation.mainShouldAbort()` can be periodically called and then early return if the operation may take more than a few seconds.
    internal final func createInteractiveOperation(
        label: String? = nil,
        weight: ProgressWeight = .default(),
        _ block: @escaping (
            _ operation: InteractiveClosureOperation,
            _ atomicValue: VariableAccess
        ) -> Void
    ) -> InteractiveClosureOperation {
        InteractiveClosureOperation(
            label: label,
            weight: weight
        ) { [weak self] operation in
            guard let self = self else { return }
            let varAccess = VariableAccess(operationQueue: self)
            block(operation, varAccess)
        }
    }
    
    /// Provides a closure to mutate the shared atomic variable and optionally return a value.
    @discardableResult
    public func withValue<U>(_ block: (_ value: inout T) throws -> U) rethrows -> U {
        try block(&sharedMutableValue)
    }
}

#endif
