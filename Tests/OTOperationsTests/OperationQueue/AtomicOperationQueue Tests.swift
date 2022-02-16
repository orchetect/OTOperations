//
//  AtomicOperationQueue Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import XCTest
@testable import OTOperations

final class AtomicOperationQueue_Tests: XCTestCase {
    
    /// Serial FIFO queue.
    func testOp_serialFIFO_Run() {
        
        let opQ = AtomicOperationQueue(type: .serialFIFO,
                                       initialMutableValue: [Int]())
        
        for val in 1...100 {
            opQ.addOperation { $0.mutate { $0.append(val) } }
        }
        
        wait(for: opQ.status == .idle, timeout: 0.5)
        //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
        //XCTAssertEqual(timeoutResult, .success)
        
        XCTAssertEqual(opQ.sharedMutableValue.count, 100)
        XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertFalse(opQ.isSuspended)
        XCTAssertEqual(opQ.status, .idle)
        
    }
    
    /// Concurrent automatic threading. Run it.
    func testOp_concurrentAutomatic_Run() {
        
        let opQ = AtomicOperationQueue(type: .concurrentAutomatic,
                                       initialMutableValue: [Int]())
        
        for val in 1...100 {
            opQ.addOperation { $0.mutate { $0.append(val) } }
        }
        
        wait(for: opQ.status == .idle, timeout: 0.5)
        //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
        //XCTAssertEqual(timeoutResult, .success)
        
        XCTAssertEqual(opQ.sharedMutableValue.count, 100)
        // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
        XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertFalse(opQ.isSuspended)
        XCTAssertEqual(opQ.status, .idle)
        
    }
    
    /// Concurrent automatic threading. Do not run it. Check status. Run it. Check status.
    func testOp_concurrentAutomatic_Pause_Run() {
        
        let opQ = AtomicOperationQueue(type: .concurrentAutomatic,
                                       initialMutableValue: [Int]())
        
        opQ.isSuspended = true
        
        XCTAssertEqual(opQ.status, .paused)
        
        for val in 1...100 {
            opQ.addOperation { $0.mutate { $0.append(val) } }
        }
        
        XCTAssertEqual(opQ.status, .paused)
        
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 0.2)
        XCTAssertEqual(timeoutResult, .timedOut)
        
        XCTAssertEqual(opQ.sharedMutableValue, [])
        XCTAssertEqual(opQ.operationCount, 100)
        XCTAssertTrue(opQ.isSuspended)
        
        wait(for: opQ.status == .paused, timeout: 0.1)
        XCTAssertEqual(opQ.status, .paused)
        
        opQ.isSuspended = false
        wait(for: (opQ.status != .paused && opQ.status != .idle), timeout: 0.2)
        
        wait(for: opQ.status == .idle, timeout: 3.0)
        XCTAssertEqual(opQ.status, .idle)
        
        XCTAssertEqual(opQ.sharedMutableValue.count, 100)
        // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
        XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        
    }
    
    /// Concurrent automatic threading. Run it.
    func testOp_concurrentSpecific_Run() {
        
        let opQ = AtomicOperationQueue(type: .concurrent(max: 10),
                                       initialMutableValue: [Int]())
        
        for val in 1...100 {
            opQ.addOperation { $0.mutate { $0.append(val) } }
        }
        
        wait(for: opQ.status == .idle, timeout: 0.5)
        //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
        //XCTAssertEqual(timeoutResult, .success)
        
        XCTAssertEqual(opQ.sharedMutableValue.count, 100)
        // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
        XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertFalse(opQ.isSuspended)
        XCTAssertEqual(opQ.status, .idle)
        
    }
    
    /// Serial FIFO queue.
    /// Test the behavior of `addOperations()`. It should add operations in array order.
    func testOp_serialFIFO_AddOperations_Run() {
        
        let opQ = AtomicOperationQueue(type: .serialFIFO,
                                       initialMutableValue: [Int]())
        var ops: [Operation] = []
        
        // first generate operation objects
        for val in 1...50 {
            let op = opQ.createOperation { $0.mutate { $0.append(val) } }
            ops.append(op)
        }
        for val in 51...100 {
            let op = opQ.createInteractiveOperation { _, v in
                v.mutate { $0.append(val) }
            }
            ops.append(op)
        }
        
        // then addOperations() with all 100 operations
        opQ.addOperations(ops, waitUntilFinished: false)
        
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 1.0)
        XCTAssertEqual(timeoutResult, .success)
        
        XCTAssertEqual(opQ.sharedMutableValue.count, 100)
        XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertFalse(opQ.isSuspended)
        XCTAssertEqual(opQ.status, .idle)
        
    }
    
    /// NOTE: this test similar to one in: BasicOperationQueue Tests.swift
    func testResetProgressWhenFinished_True() {
        
        let opQ = AtomicOperationQueue(type: .serialFIFO,
                                       resetProgressWhenFinished: true,
                                       initialMutableValue: 0) // value doesn't matter
        
        for _ in 1...10 {
            opQ.addInteractiveOperation { _,_ in usleep(100_000) }
        }
        
        XCTAssertEqual(opQ.progress.totalUnitCount, 10 * 100)
        
        switch opQ.status {
        case .inProgress:
            break // correct
        default:
            XCTFail()
        }
        
        wait(for: opQ.status == .idle, timeout: 5.0)
        
        wait(for: opQ.progress.totalUnitCount == 1, timeout: 0.5)
        XCTAssertEqual(opQ.progress.totalUnitCount, 1)
        
    }
    
}

#endif
