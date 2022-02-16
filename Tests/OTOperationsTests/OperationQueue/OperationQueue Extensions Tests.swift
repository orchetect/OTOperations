//
//  OperationQueue Extensions Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

import XCTest
import OTOperations
import OTAtomics

final class OperationQueueExtensions_Success_Tests: XCTestCase {
    
    override func setUp() { super.setUp() }
    override func tearDown() { super.tearDown() }
    
    @OTAtomicsThreadSafe fileprivate var val = 0
    
    func testWaitUntilAllOperationsAreFinished_Timeout_Success() {
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1 // serial
        opQ.isSuspended = true
        
        val = 0
        
        opQ.addOperation {
            usleep(100_000)
            self.val = 1
        }
        
        opQ.isSuspended = false
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 0.5)
        
        XCTAssertEqual(timeoutResult, .success)
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertEqual(val, 1)
        
    }
    
}

final class OperationQueueExtensions_TimedOut_Tests: XCTestCase {
    
    override func setUp() { super.setUp() }
    override func tearDown() { super.tearDown() }
    
    @OTAtomicsThreadSafe fileprivate var val = 0
    
    func testWaitUntilAllOperationsAreFinished_Timeout_TimedOut() {
        
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1 // serial
        opQ.isSuspended = true
        
        val = 0
        
        opQ.addOperation {
            sleep(1) // seconds
            self.val = 1
        }
        
        opQ.isSuspended = false
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 0.5)
        
        XCTAssertEqual(timeoutResult, .timedOut)
        XCTAssertEqual(opQ.operationCount, 1)
        XCTAssertEqual(val, 0)
        
    }
    
}

#endif
