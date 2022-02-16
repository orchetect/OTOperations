//
//  BasicOperationQueue Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import XCTest
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
        
        XCTAssertEqual(opQ.maxConcurrentOperationCount,
                       OperationQueue.defaultMaxConcurrentOperationCount)
        
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
        wait(for: opQ.lastAddedOperation == nil, timeout: 0.5)
        
    }
    
    func testResetProgressWhenFinished_False() {
        
        let opQ = BasicOperationQueue(type: .serialFIFO,
                                      resetProgressWhenFinished: false)
        
        for _ in 1...10 {
            opQ.addOperation { }
        }
        
        wait(for: opQ.status == .idle, timeout: 0.5)
        wait(for: opQ.operationCount == 0, timeout: 0.5)
        
        XCTAssertEqual(opQ.progress.totalUnitCount, 10 * 100)
        
        for _ in 1...10 {
            opQ.addOperation { }
        }
        
        wait(for: opQ.status == .idle, timeout: 0.5)
        wait(for: opQ.operationCount == 0, timeout: 0.5)
        
        XCTAssertEqual(opQ.progress.totalUnitCount, 20 * 100)
        
    }
    
    func testResetProgressWhenFinished_True() {
        
        class OpQProgressTest {
            var statuses: [OperationQueueStatus] = []
            
            let opQ = AtomicOperationQueue(type: .serialFIFO,
                                           resetProgressWhenFinished: true,
                                           initialMutableValue: 0)
            
            init() {
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
        
        let ppQProgressTest = OpQProgressTest()
        
        func runTen() {
            ppQProgressTest.opQ.cancelAllOperations()
            
            print("Running 10 operations...")
            for _ in 1...10 {
                // pick random operation types to add,
                // each taking the same amount of time to execute
                switch (0...4).randomElement()! {
                case 0:
                    ppQProgressTest.opQ.addOperation {
                        usleep(100_000)
                    }
                case 1:
                    ppQProgressTest.opQ.addOperation(
                        .basic {
                            usleep(100_000)
                        }
                    )
                case 2:
                    ppQProgressTest.opQ.addOperation(
                        .interactive { operation in
                            usleep(100_000)
                        }
                    )
                case 3:
                    ppQProgressTest.opQ.addOperation(
                        .interactiveAsync { operation in
                            usleep(100_000)
                            operation.completeOperation()
                        }
                    )
                case 4:
                    ppQProgressTest.opQ.addOperation(
                        .atomicBlock(type: .concurrentAutomatic,
                                     initialMutableValue: 0) { opBlock in
                                         opBlock.addOperation { _ in
                                             usleep(100_000)
                                         }
                                     }
                    )
                default:
                    XCTFail()
                }
            }
            
            XCTAssertEqual(ppQProgressTest.opQ.progress.totalUnitCount, 10 * 100)
            
            switch ppQProgressTest.opQ.status {
            case .inProgress(fractionCompleted: _, message: _):
                break // correct
            default:
                XCTFail()
            }
            
            wait(for: ppQProgressTest.opQ.status == .idle, timeout: 1.5)
            
            wait(for: ppQProgressTest.opQ.progress.totalUnitCount == 1, timeout: 0.5)
            XCTAssertEqual(ppQProgressTest.opQ.progress.completedUnitCount, 1)
            XCTAssertEqual(ppQProgressTest.opQ.progress.totalUnitCount, 1)
            XCTAssertFalse(ppQProgressTest.opQ.progress.isCancelled)
        }
        
        // run this global async, since the statusHandler gets called on main
        let runExp = expectation(description: "Test Run")
        DispatchQueue.global().async {
            runTen()
            usleep(500_000)
            runTen()
            runExp.fulfill()
        }
        wait(for: [runExp], timeout: 10.0)
        
        XCTAssertEqual(ppQProgressTest.statuses, [
            .idle,
            .inProgress(fractionCompleted: 0.0, message: "0% completed"),
            .inProgress(fractionCompleted: 0.1, message: "10% completed"),
            .inProgress(fractionCompleted: 0.2, message: "20% completed"),
            .inProgress(fractionCompleted: 0.3, message: "30% completed"),
            .inProgress(fractionCompleted: 0.4, message: "40% completed"),
            .inProgress(fractionCompleted: 0.5, message: "50% completed"),
            .inProgress(fractionCompleted: 0.6, message: "60% completed"),
            .inProgress(fractionCompleted: 0.7, message: "70% completed"),
            .inProgress(fractionCompleted: 0.8, message: "80% completed"),
            .inProgress(fractionCompleted: 0.9, message: "90% completed"),
            .idle,
            .inProgress(fractionCompleted: 0.0, message: "0% completed"),
            .inProgress(fractionCompleted: 0.1, message: "10% completed"),
            .inProgress(fractionCompleted: 0.2, message: "20% completed"),
            .inProgress(fractionCompleted: 0.3, message: "30% completed"),
            .inProgress(fractionCompleted: 0.4, message: "40% completed"),
            .inProgress(fractionCompleted: 0.5, message: "50% completed"),
            .inProgress(fractionCompleted: 0.6, message: "60% completed"),
            .inProgress(fractionCompleted: 0.7, message: "70% completed"),
            .inProgress(fractionCompleted: 0.8, message: "80% completed"),
            .inProgress(fractionCompleted: 0.9, message: "90% completed"),
            .idle
        ])
        
    }
    
    func testStatus() {
        
        let opQ = BasicOperationQueue(type: .serialFIFO)
        
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
        case .inProgress(let fractionCompleted, let message):
            XCTAssertEqual(fractionCompleted, 0.0)
            _ = message // don't test message content, for now
        default:
            XCTFail()
        }
        
        wait(for: [completionBlockExp], timeout: 0.5)
        wait(for: opQ.operationCount == 0, timeout: 0.5)
        wait(for: opQ.progress.isFinished, timeout: 0.5)
        
        XCTAssertEqual(opQ.status, .idle)
        
        opQ.isSuspended = true
        
        XCTAssertEqual(opQ.status, .paused)
        
        opQ.isSuspended = false
        
        XCTAssertEqual(opQ.status, .idle)
        
    }
    
}

#endif
