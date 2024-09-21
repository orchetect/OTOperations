//
//  BasicOperation.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if canImport(Foundation)

import Foundation
import OTAtomics

/// A synchronous or asynchronous `Operation` subclass that provides essential boilerplate.
/// `BasicOperation` is designed to be subclassed.
///
/// By default this operation is synchronous. If the operation is run without being inserted into an `OperationQueue`, when you call the `start()` method the operation executes immediately in the current thread. By the time the `start()` method returns control, the operation is complete.
///
/// If asynchronous behavior is required then use `BasicAsyncOperation` instead.
///
/// **Usage**
///
/// This object is designed to be subclassed.
///
/// Refer to the following example for calls that must be made within the main closure block:
///
///     class MyOperation: BasicOperation {
///         override func main() {
///             // At the start, call this and conditionally return:
///             guard mainShouldStart() else { return }
///
///             // ... do some work ...
///
///             // Optionally:
///             // If the operation may take more than a few seconds,
///             // periodically check and and return early:
///             if mainShouldAbort() { return }
///
///             // ... do some work ...
///
///             // Finally, at the end of the operation call:
///             completeOperation()
///         }
///     }
///
/// - important: This object is designed to be subclassed. See the Foundation documentation for `Operation` regarding overriding `start()` and be sure to follow the guidelines in these inline docs regarding `BasicOperation` specifically.
open class BasicOperation: Operation,
                           ProgressReporting,
                           @unchecked Sendable // Sendable should be ok since both Operation and Progress are Sendable
{
    // MARK: - Progress
    
    /// Progress object representing progress of the operation.
    public private(set) var progress: Progress = LabelProgress(totalUnitCount: 1)
   
    /// Return `.progress` typed as `LabelProgress` in order to get or set label information.
    public final var labelProgress: LabelProgress {
        progress as! LabelProgress
    }
    
    /// Progress weight when the operation is added to a `BasicOperationQueue` or one of its subclasses.
    public var progressWeight: BasicOperationQueue.ProgressWeight
    
    // MARK: - KVO
    
    // adding KVO compliance
    @objc override public final dynamic
    var isExecuting: Bool { _isExecuting }
    @OTAtomicsThreadSafe private var _isExecuting = false {
        willSet { willChangeValue(for: \.isExecuting) }
        didSet { didChangeValue(for: \.isExecuting) }
    }
    
    // adding KVO compliance
    @objc override public final dynamic
    var isFinished: Bool { _isFinished }
    @OTAtomicsThreadSafe private var _isFinished = false {
        willSet { willChangeValue(for: \.isFinished) }
        didSet { didChangeValue(for: \.isFinished) }
    }
    
    // adding KVO compliance
    @objc override public final dynamic
    var qualityOfService: QualityOfService {
        get { _qualityOfService }
        set { _qualityOfService = newValue }
    }

    private var _qualityOfService: QualityOfService = .default {
        willSet { willChangeValue(for: \.qualityOfService) }
        didSet { didChangeValue(for: \.qualityOfService) }
    }
    
    public init(
        label: String? = nil,
        weight: BasicOperationQueue.ProgressWeight = .default()
    ) {
        progressWeight = weight
        super.init()
        
        if label != nil { labelProgress.label = label }
        
        progress.cancellationHandler = { [weak progress] in
            guard let progress = progress else { return }
            
            // automatically set progress to finished state if cancelled
            progress.completedUnitCount = progress.totalUnitCount
        }
    }
    
    // MARK: - Method Overrides
    
    override public final func start() {
        if isCancelled { completeOperation(dueToCancellation: true) }
        super.start()
    }
    
    override public final func cancel() {
        super.cancel()
        progress.cancel()
    }
    
    // MARK: - Methods
    
    /// Returns true if operation should begin.
    public final func mainShouldStart() -> Bool {
        guard !isCancelled else {
            completeOperation(dueToCancellation: true)
            return false
        }
        
        guard !isExecuting else { return false }
        _isExecuting = true
        return true
    }
    
    /// Call this once all execution is complete in the operation.
    /// If returning early from the operation due to `isCancelled` being true, call this with the `dueToCancellation` flag set to `true` to update this operation's progress as cancelled.
    public final func completeOperation(dueToCancellation: Bool = false) {
        if dueToCancellation {
            progress.cancel()
        }
        
        // progress object MUST ALWAYS set completed == total, even if cancelled
        // or it will not be released from its parent progress
        progress.completedUnitCount = progress.totalUnitCount
        
        _isExecuting = false
        _isFinished = true
    }
    
    /// Checks if `isCancelled` is true, and calls `completedOperation()` if so.
    /// Returns `isCancelled`.
    public final func mainShouldAbort() -> Bool {
        if isCancelled {
            completeOperation(dueToCancellation: true)
        }
        return isCancelled
    }
    
    deinit {
        // progress object MUST ALWAYS set completed == total, even if cancelled
        // or it will not be released from its parent progress
        progress.completedUnitCount = progress.totalUnitCount
    }
}

#endif
