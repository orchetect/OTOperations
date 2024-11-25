//
//  BlockOperation Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import XCTest
@testable import OTOperations
import OTAtomics

@MainActor
final class BlockOperation_Tests: XCTestCase, Sendable {
    /// This does not test a feature of OTOperations.
    /// Rather, it tests the behavior of Foundation's built-in `BlockOperation` object.
    @MainActor
    func testBlockOperation() {
        let op = BlockOperation()
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        @MainActor final class Val: Sendable {
            var value: [Int] = []
            
            func update(_ newValue: [Int]) {
                value = newValue
            }
            
            func append(_ newValue: Int) {
                value.append(newValue)
            }
        }
        
        let arr = Val()
        
        for val in 1 ... 100 { // will multi-thread
            op.addExecutionBlock {
                usleep(100_000)
                Task { await arr.append(val) }
            }
        }
        
        op.completionBlock = {
            completionBlockExp.fulfill()
        }
        
        op.start()
        
        wait(for: arr.value.count == 100, timeout: 5.0)
        
        // check that all operations executed.
        // sort them first because BlockOperation execution blocks run concurrently and may be out-of-sequence
        XCTAssertEqual(arr.value.sorted(), Array(1 ... 100))
        
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        XCTAssertTrue(op.isFinished)
        
        wait(for: [completionBlockExp], timeout: 2)
    }
}
