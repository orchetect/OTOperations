//
//  BasicOperationQueue.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if canImport(Foundation)

import Foundation
import OTAtomics

/// An `OperationQueue` subclass with useful additions.
open class BasicOperationQueue: OperationQueue {
    
    /// Any time the queue completes all of its operations and returns to an empty queue, reset the progress object's total unit count to 0.
    public final var resetProgressWhenFinished: Bool
    
    /// A reference to the `Operation` that was last added to the queue. Returns `nil` if the operation finished and no longer exists.
    public final weak var lastAddedOperation: Operation?
    
    /// Operation queue type. Determines max concurrent operation count.
    public final var operationQueueType: OperationQueueType {
        didSet {
            updateFromOperationQueueType()
        }
    }
    
    private func updateFromOperationQueueType() {
        
        switch operationQueueType {
        case .serialFIFO:
            maxConcurrentOperationCount = 1
            
        case .concurrentAutomatic:
            maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
            
        case .concurrent(let maxConcurrentOperations):
            maxConcurrentOperationCount = maxConcurrentOperations
        }
        
    }
    
    @OTAtomicsThreadSafe private var done = true
    
    // MARK: - Status
    
    @OTAtomicsThreadSafe private var _status: OperationQueueStatus = .idle
    
    /// Operation queue status.
    /// To observe changes to this value, supply a closure to the `statusHandler` property.
    public private(set) var status: OperationQueueStatus {
        get {
            _status
        }
        set {
            let oldValue = _status
            _status = newValue
            
            if newValue != oldValue {
                DispatchQueue.main.async {
                    self.statusHandler?(newValue, oldValue)
                }
            }
        }
    }
    
    public typealias StatusHandler = (_ newStatus: OperationQueueStatus,
                                      _ oldStatus: OperationQueueStatus) -> Void
    
    /// Handler called any time the `status` property changes.
    /// Handler is called async on the main thread.
    public final var statusHandler: StatusHandler?
    
    // MARK: - Progress Back-Porting
    
    @OTAtomicsThreadSafe
    private var _progress: Progress = LabelProgress(totalUnitCount: 0)
    
    @available(macOS 10.9, iOS 7.0, tvOS 9.0, watchOS 2.0, *)
    @objc dynamic
    public override final var progress: Progress { _progress }
    
    /// Return `.progress` typed as `LabelProgress` in order to get or set label information.
    public final var labelProgress: LabelProgress {
        
        progress as! LabelProgress
        
    }
    
    // MARK: - Init
    
    /// Set max concurrent operation count.
    /// Status handler is called async on the main thread.
    public init(type operationQueueType: OperationQueueType,
                label: String? = nil,
                resetProgressWhenFinished: Bool = false,
                statusHandler: StatusHandler? = nil) {
        
        self.operationQueueType = operationQueueType
        self.resetProgressWhenFinished = resetProgressWhenFinished
        self.statusHandler = statusHandler
        
        super.init()
        
        self.labelProgress.label = label
        
        updateFromOperationQueueType()
        
        addObservers()
        
    }
    
    // MARK: - Overrides
    
    /// Add an operation to the operation queue.
    public final override func addOperation(
        _ op: Operation
    ) {
        
        // failsafe reset of progress to known state if queue is empty
        var resetTotalUnitCountNudge = false
        if resetProgressWhenFinished, operationCount == 0 {
            if let children = progress.value(forKeyPath: "children") as? NSMutableSet,
               children.count > 0
            {
                // this is jank, but manually remove all children
                children
                    .allObjects
                    .filter { $0 is LabelProgress }
                    .forEach { children.remove($0) }
                
                //assertionFailure("operationCount is 0 but progress children is not empty - possible retain cycle")
            }
            
            progress.completedUnitCount = 0
            progress.totalUnitCount = 1
            resetTotalUnitCountNudge = true
        }
        
        switch operationQueueType {
        case .serialFIFO:
            // to enforce a serial queue, we add the previous operation as a dependency to the new one if it still exists
            if let lastOp = lastAddedOperation {
                op.addDependency(lastOp)
            }
        default:
            break
        }
        
        // update progress
        if let basicOp = op as? BasicOperation {
            let units = basicOp.progressWeight.rawValue
            progress.totalUnitCount += units
            progress.addChild(basicOp.progress,
                              withPendingUnitCount: units)
        } else {
            progress.totalUnitCount += 1
        }
        
        lastAddedOperation = op
        
        if resetTotalUnitCountNudge {
            progress.totalUnitCount -= 1
        }
        done = false
        super.addOperation(op)
        
    }
    
    /// Add an operation block.
    public final override func addOperation(
        _ block: @escaping () -> Void
    ) {
        
        // wrap in an actual operation object so we can track it
        let op = ClosureOperation {
            block()
        }
        addOperation(op)
        
    }
    
    /// Add operation blocks.
    /// If queue type is Serial FIFO, operations will be added in array order.
    public final override func addOperations(
        _ ops: [Operation],
        waitUntilFinished wait: Bool
    ) {
        guard !ops.isEmpty else { return }
        
        // failsafe reset of progress to known state if queue is empty
        var resetTotalUnitCountNudge = false
        if resetProgressWhenFinished, operationCount == 0 {
            if let children = progress.value(forKeyPath: "children") as? NSMutableSet,
               children.count > 0
            {
                // this is jank, but manually remove all children
                children
                    .allObjects
                    .filter { $0 is LabelProgress }
                    .forEach { children.remove($0) }
                
                //assertionFailure("operationCount is 0 but progress children is not empty - possible retain cycle")
            }
            
            progress.completedUnitCount = 0
            progress.totalUnitCount = 1
            resetTotalUnitCountNudge = true
        }
        
        switch operationQueueType {
        case .serialFIFO:
            // to enforce a serial queue, we add the previous operation as a dependency to the new one if it still exists
            var parentOperation: Operation? = lastAddedOperation
            ops.forEach {
                if let parentOperation = parentOperation {
                    $0.addDependency(parentOperation)
                }
                parentOperation = $0
            }
            
        default:
            break
        }
        
        // update progress
        for op in ops {
            if let basicOp = op as? BasicOperation {
                let units = basicOp.progressWeight.rawValue
                progress.totalUnitCount += units
                progress.addChild(basicOp.progress,
                                  withPendingUnitCount: units)
            } else {
                progress.totalUnitCount += 1
            }
        }
        
        lastAddedOperation = ops.last
        
        if resetTotalUnitCountNudge {
            progress.totalUnitCount -= 1
        }
        done = false
        super.addOperations(ops, waitUntilFinished: wait)
        
    }
    
    // MARK: - Convenience Operations
    
    /// Add an operation block.
    public final func addOperation(
        weight: ProgressWeight = .default(),
        _ block: @escaping () -> Void
    ) {
       
        // wrap in an actual operation object so we can track it
        let op = ClosureOperation {
            block()
        }
        op.progressWeight = weight
        addOperation(op)
        
    }
    
    // MARK: - KVO Observers
    
    /// Retain property observers. For safety, this array must be emptied on class deinit.
    private var observers: [NSKeyValueObservation] = []
    
    private func addObservers() {
        
        // self.isSuspended
        
        observers.append(
            observe(\.isSuspended, options: [.new])
            { [self, progress] _, _ in
                // !!! DO NOT USE [weak self] HERE. MUST BE STRONG SELF !!!
                
                if isSuspended {
                    status = .paused
                } else {
                    if done ||
                        progress.isFinished
                    {
                        setStatusIdle(resetProgress: false)
                    } else {
                        status = .inProgress(
                            fractionCompleted: progress.fractionCompleted,
                            label: labelProgress.deepLabel,
                            description: progress.localizedDescription
                        )
                        
                    }
                }
            }
        )
        
        // self.operationCount
        
        observers.append(
            observe(\.operationCount, options: [.new])
            { [self, progress] _, _ in
                // !!! DO NOT USE [weak self] HERE. MUST BE STRONG SELF !!!
                
                done = operationCount == 0
                
                guard !isSuspended else { return }

                if !done,
                   !progress.isFinished,
                   operationCount > 0
                {
                    status = .inProgress(fractionCompleted: progress.fractionCompleted,
                                         label: labelProgress.deepLabel,
                                         description: progress.localizedDescription)
                } else {
                    setStatusIdle(resetProgress: resetProgressWhenFinished)
                }
            }
        )
        
        // self.progress.fractionCompleted
        // (NSProgress docs state that fractionCompleted is KVO-observable)
        
        observers.append(
            progress.observe(\.fractionCompleted, options: [.new])
            { [self, progress] _, _ in
                // !!! DO NOT USE [weak self] HERE. MUST BE STRONG SELF !!!
                
                guard !isSuspended else { return }
                
                if done ||
                    progress.isFinished ||
                    operationCount == 0
                {
                    setStatusIdle(resetProgress: resetProgressWhenFinished)
                } else {
                    status = .inProgress(fractionCompleted: progress.fractionCompleted,
                                         label: labelProgress.deepLabel,
                                         description: progress.localizedDescription)
                }
            }
        )
        
        // self.progress.isFinished
        // (NSProgress docs state that isFinished is KVO-observable)
        
        observers.append(
            progress.observe(\.isFinished, options: [.new])
            { [self, progress] _, _ in
                // !!! DO NOT USE [weak self] HERE. MUST BE STRONG SELF !!!
                
                if progress.isFinished {
                    setStatusIdle(resetProgress: resetProgressWhenFinished)
                }
            }
        )
        
    }
    
    private func removeObservers() {
        
        observers.forEach { $0.invalidate() } // for extra safety, invalidate them first
        observers.removeAll()
        
    }
    
    /// Only call as a result of the queue emptying
    private func setStatusIdle(resetProgress: Bool) {
        // delay the progress reset, in case more operations
        // are added soon after the operation queue empties
        if resetProgress {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                if self.operationCount == 0 {
                    // DO NOT SET totalUnitCount to 0 here!!!
                    // IF YOU SET IT TO 0, PRODUCTION CODE WILL FAIL
                    // EVEN THOUGH THE PACKAGE'S UNIT TESTS WORK CORRECTLY.
                    
                    self.progress.totalUnitCount = 1
                    self.progress.completedUnitCount = 1
                }
            }
        }
        
        done = true
        status = .idle
    }
    
    deinit {
        
        // this is very important or it may result in random crashes if the KVO observers aren't nuked at the appropriate time
        removeObservers()
        
    }
    
}

#endif
