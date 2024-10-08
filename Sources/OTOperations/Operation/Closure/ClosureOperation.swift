//
//  ClosureOperation.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation

// NOTE: when updating this inline docs block, copy it over to
// `AtomicOperationQueue.addOperation()`
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
public final class ClosureOperation: BasicOperation, @unchecked Sendable {
    override public final var isAsynchronous: Bool { false }
    
    public final var mainBlock: () -> Void
    
    public init(
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default(),
        _ mainBlock: @escaping () -> Void
    ) {
        self.mainBlock = mainBlock
        super.init(label: label, weight: weight)
    }
    
    override public func main() {
        guard mainShouldStart() else { return }
        mainBlock()
        completeOperation()
    }
}

#endif
