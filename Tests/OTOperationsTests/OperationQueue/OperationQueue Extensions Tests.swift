//
//  OperationQueue Extensions Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import Foundation
import Testing
import OTOperations
import OTAtomics
import XCTestUtils

@Suite struct OperationQueueExtensions_Success_Tests {
    @MainActor
    @Test func testWaitUntilAllOperationsAreFinished_Timeout_Success() async throws {
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1 // serial
        opQ.isSuspended = true
        
        var val = 0
        
        opQ.addOperation { 
            usleep(100_000)
            Task { @MainActor in val = 1 }
        }
        
        opQ.isSuspended = false
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 0.5)
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        #expect(timeoutResult == .success)
        #expect(opQ.operationCount == 0)
        #expect(val == 1)
    }
}

@Suite struct OperationQueueExtensions_TimedOut_Tests {
    @MainActor
    @Test func testWaitUntilAllOperationsAreFinished_Timeout_TimedOut() async throws {
        let opQ = OperationQueue()
        opQ.maxConcurrentOperationCount = 1 // serial
        opQ.isSuspended = true
        
        var val = 0
        
        opQ.addOperation {
            sleep(1) // seconds
            Task { @MainActor in val = 1 }
        }
        
        opQ.isSuspended = false
        let timeoutResult = opQ.waitUntilAllOperationsAreFinished(timeout: 0.5)
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
        
        #expect(timeoutResult == .timedOut)
        #expect(opQ.operationCount == 1)
        #expect(val == 0)
    }
}
