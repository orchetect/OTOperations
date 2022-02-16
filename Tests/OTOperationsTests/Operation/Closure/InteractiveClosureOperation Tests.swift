//
//  InteractiveClosureOperation Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import XCTest
import OTOperations

final class InteractiveClosureOperation_Tests: XCTestCase {
    
    func testOpRun() {
        
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let op = InteractiveClosureOperation { operation in
            mainBlockExp.fulfill()
            XCTAssertTrue(operation.isExecuting)
            
            // do some work...
            if operation.mainShouldAbort() { return }
            // do some work...
        }
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        op.start()
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 0.5)

        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        
    }
    
    func testOpNotRun() {
        
        let mainBlockExp = expectation(description: "Main Block Called")
        mainBlockExp.isInverted = true
        
        let op = InteractiveClosureOperation { operation in
            mainBlockExp.fulfill()
            XCTAssertTrue(operation.isExecuting)
            
            // do some work...
            if operation.mainShouldAbort() { return }
            // do some work...
        }
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        completionBlockExp.isInverted = true
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 0.3)

        // state
        XCTAssertTrue(op.isReady)
        XCTAssertFalse(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        
    }
    
    /// Test in the context of an OperationQueue. Run is implicit.
    func testQueue() {
        
        let opQ = OperationQueue()
        
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let op = InteractiveClosureOperation { operation in
            mainBlockExp.fulfill()
            XCTAssertTrue(operation.isExecuting)
            
            // do some work...
            if operation.mainShouldAbort() { return }
            // do some work...
        }
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        // queue automatically starts the operation once it's added
        opQ.addOperation(op)
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 0.5)
        
        XCTAssertEqual(opQ.operationCount, 0)

        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        
    }
    
    /// Test that start() runs synchronously. Run it.
    func testOp_SynchronousTest_Run() {
        
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        var val = 0
        
        let op = InteractiveClosureOperation { operation in
            mainBlockExp.fulfill()
            XCTAssertTrue(operation.isExecuting)
            usleep(500_000)
            val = 1
        }
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        op.start()
        
        XCTAssertEqual(val, 1)
        
        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 2)
        
    }
    
}

#endif
