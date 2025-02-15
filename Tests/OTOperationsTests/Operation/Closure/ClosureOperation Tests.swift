//
//  ClosureOperation Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import XCTest
import OTOperations

final class ClosureOperation_Tests: XCTestCase {
    override func setUpWithError() throws {
        mainCheck = { }
    }
    
    private var mainCheck: () -> Void = { }
    
    func testOpRun() {
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let op = ClosureOperation {
            self.mainCheck()
        }
         
        // have to define this after ClosureOperation is initialized, since it can't reference itself in its own initializer closure
        mainCheck = {
            mainBlockExp.fulfill()
            XCTAssertTrue(op.isExecuting)
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
        // progress
        XCTAssertFalse(op.progress.isCancelled)
        XCTAssertEqual(op.progress.fractionCompleted, 1.0)
        XCTAssertFalse(op.progress.isIndeterminate)
    }
    
    func testOpNotRun() {
        let mainBlockExp = expectation(description: "Main Block Called")
        mainBlockExp.isInverted = true
        
        let op = ClosureOperation {
            self.mainCheck()
        }
        
        // have to define this after ClosureOperation is initialized, since it can't reference itself in its own initializer closure
        mainCheck = {
            mainBlockExp.fulfill()
            XCTAssertTrue(op.isExecuting)
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
        // progress
        XCTAssertFalse(op.progress.isCancelled)
        XCTAssertEqual(op.progress.fractionCompleted, 0.0)
        XCTAssertFalse(op.progress.isIndeterminate)
    }
    
    /// Test as a standalone operation. Cancel it before it runs.
    func testOpCancelBeforeRun() {
        let mainBlockExp = expectation(description: "Main Block Called")
        mainBlockExp.isInverted = true
        
        let op = ClosureOperation {
            self.mainCheck()
        }
        
        // have to define this after ClosureOperation is initialized, since it can't reference itself in its own initializer closure
        mainCheck = {
            mainBlockExp.fulfill()
            XCTAssertTrue(op.isExecuting)
        }
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        op.cancel()
        op
            .start() // in an OperationQueue, all operations must start even if they're already cancelled
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 0.3)
        
        // state
        XCTAssertTrue(op.isReady)
        XCTAssertTrue(op.isFinished)
        XCTAssertTrue(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        // progress
        XCTAssertTrue(op.progress.isCancelled)
        XCTAssertEqual(op.progress.fractionCompleted, 1.0)
        XCTAssertFalse(op.progress.isIndeterminate)
    }
    
    /// Test in the context of an OperationQueue. Run is implicit.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testQueue() {
        let opQ = OperationQueue()
        
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let op = ClosureOperation {
            self.mainCheck()
        }
        
        // have to define this after ClosureOperation is initialized, since it can't reference itself in its own initializer closure
        mainCheck = {
            mainBlockExp.fulfill()
            XCTAssertTrue(op.isExecuting)
        }
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        // must manually increment for OperationQueue
        opQ.progress.totalUnitCount += 1
        // queue automatically starts the operation once it's added
        opQ.addOperation(op)
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 0.5)
        
        // state
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        // progress - operation
        XCTAssertFalse(op.progress.isCancelled)
        XCTAssertEqual(op.progress.fractionCompleted, 1.0)
        XCTAssertFalse(op.progress.isIndeterminate)
        // progress - queue
        XCTAssertTrue(opQ.progress.isFinished)
        XCTAssertFalse(opQ.progress.isCancelled)
        XCTAssertEqual(opQ.progress.fractionCompleted, 1.0)
        XCTAssertFalse(opQ.progress.isIndeterminate)
    }
    
    /// Test that start() runs synchronously. Run it.
    func testOp_SynchronousTest_Run() {
        let mainBlockExp = expectation(description: "Main Block Called")
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        var val = 0
        
        let op = ClosureOperation {
            self.mainCheck()
            usleep(500_000)
            val = 1
        }
        
        // have to define this after ClosureOperation is initialized, since it can't reference itself in its own initializer closure
        mainCheck = {
            mainBlockExp.fulfill()
            XCTAssertTrue(op.isExecuting)
        }
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        op.start()
        
        // state
        XCTAssertEqual(val, 1)
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        // progress
        XCTAssertFalse(op.progress.isCancelled)
        XCTAssertEqual(op.progress.fractionCompleted, 1.0)
        XCTAssertFalse(op.progress.isIndeterminate)
        
        wait(for: [mainBlockExp, completionBlockExp], timeout: 2)
    }
}
