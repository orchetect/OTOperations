//
//  BasicOperationQueue Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

#if shouldTestCurrentPlatform

import XCTest
import XCTestUtils
@testable import OTOperations

final class BasicOperationQueue_Tests: XCTestCase {
    /// Serial FIFO queue.
    func testOperationQueueType_serialFIFO() {
        let opQ = BasicOperationQueue(type: .serialFIFO)
        
        XCTAssertEqual(opQ.maxConcurrentOperationCount, 1)
    }
    
    /// Automatic concurrency.
    func testOperationQueueType_automatic() {
        let opQ = BasicOperationQueue(type: .concurrentAutomatic)
        
        print(opQ.maxConcurrentOperationCount)
        
        XCTAssertEqual(
            opQ.maxConcurrentOperationCount,
            OperationQueue.defaultMaxConcurrentOperationCount
        )
    }
    
    /// Specific number of concurrent operations.
    func testOperationQueueType_specific() {
        let opQ = BasicOperationQueue(type: .concurrent(max: 2))
        
        print(opQ.maxConcurrentOperationCount)
        
        XCTAssertEqual(opQ.maxConcurrentOperationCount, 2)
    }
    
    func testLastAddedOperation() {
        let opQ = BasicOperationQueue(type: .serialFIFO)
        opQ.isSuspended = true
        XCTAssertEqual(opQ.lastAddedOperation, nil)
        
        var op: Operation? = Operation()
        opQ.addOperation(op!)
        XCTAssertEqual(opQ.lastAddedOperation, op)
        // just FYI: op.isFinished == false here
        // but we don't care since it doesn't affect this test
        
        op = nil
        opQ.isSuspended = false
        wait(for: opQ.lastAddedOperation, equals: nil, timeout: 0.5)
    }
    
    func testResetProgressWhenFinished_False() {
        let opQ = BasicOperationQueue(
            type: .serialFIFO,
            resetProgressWhenFinished: false
        )
        
        for _ in 1 ... 10 {
            opQ.addOperation { }
        }
        
        wait(for: opQ.status, equals: .idle, timeout: 0.5)
        wait(for: opQ.operationCount, equals: 0, timeout: 0.5)
        
        XCTAssertEqual(opQ.progress.totalUnitCount, 10 * 100)
        
        for _ in 1 ... 10 {
            opQ.addOperation { }
        }
        
        wait(for: opQ.status, equals: .idle, timeout: 0.5)
        wait(for: opQ.operationCount, equals: 0, timeout: 0.5)
        
        XCTAssertEqual(opQ.progress.totalUnitCount, 20 * 100)
    }
    
    func testResetProgressWhenFinished_True_CancelMidway() {
        class BasicOperationQueueResetTest {
            let opQ = AtomicOperationQueue(
                type: .concurrentAutomatic,
                resetProgressWhenFinished: true,
                initialMutableValue: 0
            )
            init() {
                for _ in 1 ... 10 {
                    opQ.addOperation(.atomicBlock(
                        type: .serialFIFO,
                        initialMutableValue: 0
                    ) { operation in
                        operation.addInteractiveOperation(label: nil) { operation, atomicValue in
                            usleep(10000 * UInt32.random(in: 1 ... 10))
                            if operation.mainShouldAbort() { return }
                            usleep(10000 * UInt32.random(in: 1 ... 10))
                            atomicValue.withValue { $0 += 1 }
                            usleep(10000 * UInt32.random(in: 1 ... 10))
                            operation.progress.completedUnitCount = 0
                            operation.completeOperation()
                        }
                    })
                    opQ.addInteractiveOperation(label: nil) { operation, atomicValue in
                        usleep(10000 * UInt32.random(in: 1 ... 10))
                        if operation.mainShouldAbort() { return }
                        usleep(10000 * UInt32.random(in: 1 ... 10))
                        atomicValue.withValue { $0 += 1 }
                        usleep(10000 * UInt32.random(in: 1 ... 10))
                        operation.progress.completedUnitCount = 0
                        operation.completeOperation()
                    }
                }
            }
        }
        
        let qTest = BasicOperationQueueResetTest()
        
        XCTAssertGreaterThan(qTest.opQ.operationCount, 0)
        
        // wait until at least a few operations are complete
        wait(for: qTest.opQ.status.inProgressFractionCompleted ?? -1 > 0.3, timeout: 1.0)
        
        // cancel operation queue
        qTest.opQ.cancelAllOperations()
        
        // test that progress resets
        wait(for: qTest.opQ.operationCount, equals: 0, timeout: 0.5)
        wait(for: qTest.opQ.progress.isFinished, timeout: 0.5)
        wait(for: qTest.opQ.progress.completedUnitCount, equals: 1, timeout: 0.5)
        wait(for: qTest.opQ.progress.totalUnitCount, equals: 1, timeout: 0.5)
    }
    
    func testResetProgressWhenFinished_True() {
        class AtomicOperationQueueProgressTest {
            var statuses: [OperationQueueStatus] = []
            
            let opQ = AtomicOperationQueue(
                type: .serialFIFO,
                resetProgressWhenFinished: true,
                initialMutableValue: 0
            )
            
            init() {
                opQ.labelProgress.label = "Main"
                
                opQ.statusHandler = { newStatus, oldStatus in
                    if self.statuses.isEmpty {
                        self.statuses.append(oldStatus)
                        print("-", oldStatus)
                    }
                    self.statuses.append(newStatus)
                    print("-", newStatus)
                }
            }
        }
        
        let qTest = AtomicOperationQueueProgressTest()
        
        func runTen() {
            qTest.opQ.cancelAllOperations()
            
            print("Running 10 operations...")
            for _ in 1 ... 10 {
                // pick random operation types to add,
                // each taking the same amount of time to execute
                switch (0 ... 0).randomElement() { // (0...4).randomElement()! {
                case 0:
                    qTest.opQ.addOperation {
                        usleep(100_000)
                    }
                // case 1:
                //    qTest.opQ.addOperation(
                //        .basic {
                //            usleep(100_000)
                //        }
                //    )
                // case 2:
                //    qTest.opQ.addOperation(
                //        .interactive { operation in
                //            usleep(100_000)
                //        }
                //    )
                // case 3:
                //    qTest.opQ.addOperation(
                //        .interactiveAsync { operation in
                //            usleep(100_000)
                //            operation.completeOperation()
                //        }
                //    )
                // case 4:
                //    qTest.opQ.addOperation(
                //        .atomicBlock(type: .concurrentAutomatic,
                //                     initialMutableValue: 0) { opBlock in
                //                         opBlock.addOperation { _ in
                //                             usleep(100_000)
                //                         }
                //                     }
                //    )
                default:
                    XCTFail(); return
                }
            }
            
            XCTAssertEqual(qTest.opQ.progress.totalUnitCount, 10 * 100)
            
            switch qTest.opQ.status {
            case .inProgress:
                break // correct
            default:
                XCTFail()
            }
            
            wait(for: qTest.opQ.status, equals: .idle, timeout: 3.0)
            wait(for: qTest.opQ.progress.totalUnitCount, equals: 1, timeout: 1.0)
            wait(for: qTest.opQ.progress.completedUnitCount, equals: 1, timeout: 0.2)
            XCTAssertFalse(qTest.opQ.progress.isCancelled)
        }
        
        // run this global async, since the statusHandler gets called on main
        let runExp = expectation(description: "Test Run")
        DispatchQueue.global().async {
            runTen()
            self.wait(sec: 0.5)
            runTen()
            runExp.fulfill()
        }
        wait(for: [runExp], timeout: 10.0)
        
        if qTest.statuses.count == 23 {
            XCTAssertEqual(qTest.statuses[00], .idle)
            XCTAssertEqual(qTest.statuses[01].inProgressFractionCompleted, 0.0)
            XCTAssertEqual(qTest.statuses[02].inProgressFractionCompleted, 0.1)
            XCTAssertEqual(qTest.statuses[03].inProgressFractionCompleted, 0.2)
            XCTAssertEqual(qTest.statuses[04].inProgressFractionCompleted, 0.3)
            XCTAssertEqual(qTest.statuses[05].inProgressFractionCompleted, 0.4)
            XCTAssertEqual(qTest.statuses[06].inProgressFractionCompleted, 0.5)
            XCTAssertEqual(qTest.statuses[07].inProgressFractionCompleted, 0.6)
            XCTAssertEqual(qTest.statuses[08].inProgressFractionCompleted, 0.7)
            XCTAssertEqual(qTest.statuses[09].inProgressFractionCompleted, 0.8)
            XCTAssertEqual(qTest.statuses[10].inProgressFractionCompleted, 0.9)
            XCTAssertEqual(qTest.statuses[11], .idle)
            XCTAssertEqual(qTest.statuses[12].inProgressFractionCompleted, 0.0)
            XCTAssertEqual(qTest.statuses[13].inProgressFractionCompleted, 0.1)
            XCTAssertEqual(qTest.statuses[14].inProgressFractionCompleted, 0.2)
            XCTAssertEqual(qTest.statuses[15].inProgressFractionCompleted, 0.3)
            XCTAssertEqual(qTest.statuses[16].inProgressFractionCompleted, 0.4)
            XCTAssertEqual(qTest.statuses[17].inProgressFractionCompleted, 0.5)
            XCTAssertEqual(qTest.statuses[18].inProgressFractionCompleted, 0.6)
            XCTAssertEqual(qTest.statuses[19].inProgressFractionCompleted, 0.7)
            XCTAssertEqual(qTest.statuses[20].inProgressFractionCompleted, 0.8)
            XCTAssertEqual(qTest.statuses[21].inProgressFractionCompleted, 0.9)
            XCTAssertEqual(qTest.statuses[22], .idle)
            
            //                           [00] .idle
            XCTAssertEqual(qTest.statuses[01].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[02].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[03].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[04].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[05].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[06].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[07].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[08].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[09].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[10].inProgressLabel, "Main")
            //                           [11] .idle
            XCTAssertEqual(qTest.statuses[12].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[13].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[14].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[15].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[16].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[17].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[18].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[19].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[20].inProgressLabel, "Main")
            XCTAssertEqual(qTest.statuses[21].inProgressLabel, "Main")
            //                           [22] .idle
            
            // TODO: probably shouldn't test inProgress description since it's brittle;
            // TODO: it uses localizedDescription which may not always be English
            //                           [00] .idle
            XCTAssertEqual(qTest.statuses[01].inProgressDescription, "0% completed")
            XCTAssertEqual(qTest.statuses[02].inProgressDescription, "10% completed")
            XCTAssertEqual(qTest.statuses[03].inProgressDescription, "20% completed")
            XCTAssertEqual(qTest.statuses[04].inProgressDescription, "30% completed")
            XCTAssertEqual(qTest.statuses[05].inProgressDescription, "40% completed")
            XCTAssertEqual(qTest.statuses[06].inProgressDescription, "50% completed")
            XCTAssertEqual(qTest.statuses[07].inProgressDescription, "60% completed")
            XCTAssertEqual(qTest.statuses[08].inProgressDescription, "70% completed")
            XCTAssertEqual(qTest.statuses[09].inProgressDescription, "80% completed")
            XCTAssertEqual(qTest.statuses[10].inProgressDescription, "90% completed")
            //                           [11] .idle
            XCTAssertEqual(qTest.statuses[12].inProgressDescription, "0% completed")
            XCTAssertEqual(qTest.statuses[13].inProgressDescription, "10% completed")
            XCTAssertEqual(qTest.statuses[14].inProgressDescription, "20% completed")
            XCTAssertEqual(qTest.statuses[15].inProgressDescription, "30% completed")
            XCTAssertEqual(qTest.statuses[16].inProgressDescription, "40% completed")
            XCTAssertEqual(qTest.statuses[17].inProgressDescription, "50% completed")
            XCTAssertEqual(qTest.statuses[18].inProgressDescription, "60% completed")
            XCTAssertEqual(qTest.statuses[19].inProgressDescription, "70% completed")
            XCTAssertEqual(qTest.statuses[20].inProgressDescription, "80% completed")
            XCTAssertEqual(qTest.statuses[21].inProgressDescription, "90% completed")
            //                           [22] .idle
        } else {
            XCTFail()
        }
    }
    
    func testStatus() {
        func runTest(resetWhenFinished: Bool) {
            let opQ = BasicOperationQueue(
                type: .serialFIFO,
                resetProgressWhenFinished: resetWhenFinished
            )
            
            opQ.statusHandler = { newStatus, oldStatus in
                print(oldStatus, newStatus)
            }
            
            XCTAssertEqual(opQ.status, .idle)
            
            let completionBlockExp = expectation(description: "Operation Completion")
            
            opQ.addOperation {
                usleep(100_000)
                completionBlockExp.fulfill()
            }
            
            switch opQ.status {
            case let .inProgress(fractionCompleted, label, desc):
                XCTAssertEqual(fractionCompleted, 0.0)
                _ = label // don't test label content, for now
                _ = desc // don't test desc content, for now
            default:
                XCTFail()
            }
            
            wait(for: [completionBlockExp], timeout: 0.5)
            wait(for: opQ.operationCount, equals: 0, timeout: 0.5)
            wait(for: opQ.progress.isFinished, timeout: 0.5, "progress.isFinished")
            
            XCTAssertEqual(opQ.status, .idle)
            
            opQ.isSuspended = true
            
            XCTAssertEqual(opQ.status, .paused)
            
            opQ.isSuspended = false
            
            XCTAssertEqual(opQ.status, .idle)
        }
        
        runTest(resetWhenFinished: false)
        runTest(resetWhenFinished: true)
    }
}

#endif
