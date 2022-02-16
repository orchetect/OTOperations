//
//  AtomicOperationQueue Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import XCTest
import XCTestUtils
@testable import OTOperations

final class AtomicOperationQueue_Tests: XCTestCase {
    
    /// Serial FIFO queue.
    func testOp_serialFIFO_Run() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .serialFIFO,
                                           resetProgressWhenFinished: resetWhenFinished,
                                           initialMutableValue: [Int]())
            
            for val in 1...100 {
                opQ.addOperation { $0.mutate { $0.append(val) } }
            }
            
            wait(for: opQ.status, equals: .idle, timeout: 1.0)
            //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
            //XCTAssertEqual(timeoutResult, .success)
            
            XCTAssertEqual(opQ.sharedMutableValue.count, 100)
            XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
            
            XCTAssertEqual(opQ.operationCount, 0)
            XCTAssertFalse(opQ.isSuspended)
            XCTAssertEqual(opQ.status, .idle)
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
    /// Concurrent automatic threading. Run it.
    func testOp_concurrentAutomatic_Run() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .concurrentAutomatic,
                                           resetProgressWhenFinished: resetWhenFinished,
                                           initialMutableValue: [Int]())
            
            for val in 1...100 {
                opQ.addOperation { $0.mutate { $0.append(val) } }
            }
            
            wait(for: opQ.status, equals: .idle, timeout: 0.5)
            //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
            //XCTAssertEqual(timeoutResult, .success)
            
            XCTAssertEqual(opQ.sharedMutableValue.count, 100)
            // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
            XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
            
            XCTAssertEqual(opQ.operationCount, 0)
            XCTAssertFalse(opQ.isSuspended)
            XCTAssertEqual(opQ.status, .idle)
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
    /// Concurrent automatic threading. Do not run it. Check status. Run it. Check status.
    func testOp_concurrentAutomatic_Pause_Run() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .concurrentAutomatic,
                                           initiallySuspended: true,
                                           resetProgressWhenFinished: resetWhenFinished,
                                           initialMutableValue: [Int]())
            
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
            
            wait(for: opQ.status, equals: .paused, timeout: 0.1,
                 "resetWhenFinished: \(resetWhenFinished)")
            
            opQ.isSuspended = false
            
            wait(for: opQ.status.isInProgress, timeout: 0.2,
                 "status.isInProgress, resetWhenFinished: \(resetWhenFinished)")
            
            wait(for: opQ.operationCount, equals: 0, timeout: 2.0,
                 "resetWhenFinished: \(resetWhenFinished)")
            
            wait(for: opQ.status, equals: .idle, timeout: 0.5,
                 "resetWhenFinished: \(resetWhenFinished)")
            
            XCTAssertEqual(opQ.sharedMutableValue.count, 100)
            // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
            XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
    /// Concurrent automatic threading. Run it.
    func testOp_concurrentSpecific_Run() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .concurrent(max: 10),
                                           resetProgressWhenFinished: resetWhenFinished,
                                           initialMutableValue: [Int]())
            
            for val in 1...100 {
                opQ.addOperation { $0.mutate { $0.append(val) } }
            }
            
            wait(for: opQ.status, equals: .idle, timeout: 1.0)
            //let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: .seconds(1))
            //XCTAssertEqual(timeoutResult, .success)
            
            XCTAssertEqual(opQ.sharedMutableValue.count, 100)
            // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
            XCTAssert(Array(1...100).allSatisfy(opQ.sharedMutableValue.contains))
            
            XCTAssertEqual(opQ.operationCount, 0)
            XCTAssertFalse(opQ.isSuspended)
            XCTAssertEqual(opQ.status, .idle)
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
    /// Serial FIFO queue.
    /// Test the behavior of `addOperations()`. It should add operations in array order.
    func testOp_serialFIFO_AddOperations_Run() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .serialFIFO,
                                           resetProgressWhenFinished: resetWhenFinished,
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
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
    func testResetProgressWhenFinished_True() {
        
        func runTest(resetWhenFinished: Bool) {
            let opQ = AtomicOperationQueue(type: .serialFIFO,
                                           resetProgressWhenFinished: resetWhenFinished,
                                           initialMutableValue: 0) // value doesn't matter
            
            for _ in 1...10 {
                opQ.addInteractiveOperation { _,_ in usleep(100_000) }
            }
            
            XCTAssertEqual(opQ.progress.totalUnitCount, 10 * 100)
            
            usleep(20_000)
            
            switch opQ.status {
            case .inProgress:
                break // correct
            default:
                XCTFail("Status is \(opQ.status)")
            }
            
            wait(for: opQ.status, equals: .idle, timeout: 5.0)
            
            wait(for: opQ.progress.totalUnitCount,
                 equals: resetWhenFinished ? 1 : 1000,
                 timeout: 0.5)
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
        
    }
    
}

#endif
