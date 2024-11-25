//
//  AtomicBlockOperation Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import XCTest
import XCTestUtils
@testable import OTOperations

final class AtomicBlockOperation_Tests: XCTestCase {
    func testEmpty() {
        let op = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int: [Int]]()
        )
        
        op.start()
        
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Standalone operation, serial FIFO queue mode. Run it.
    func testOp_serialFIFO_Run() {
        let op = AtomicBlockOperation(
            type: .serialFIFO,
            initialMutableValue: [Int]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        let dataVerificationExp = expectation(description: "Data Verification")
        
        for val in 1 ... 100 {
            op.addOperation { $0.withValue { $0.append(val) } }
        }
        
        op.setCompletionBlock { v in
            completionBlockExp.fulfill()
            
            // check that all operations executed and they are in serial FIFO order
            v.withValue { value in
                XCTAssertEqual(value, Array(1 ... 100))
                dataVerificationExp.fulfill()
            }
        }
        
        op.start()
        
        wait(for: [completionBlockExp, dataVerificationExp], timeout: 1)
        
        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Standalone operation, concurrent threading queue mode. Run it.
    func testOp_concurrentAutomatic_Run() {
        let op = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        let dataVerificationExp = expectation(description: "Data Verification")
        
        for val in 1 ... 100 {
            op.addOperation { $0.withValue { $0.append(val) } }
        }
        
        op.setCompletionBlock { v in
            completionBlockExp.fulfill()
            
            v.withValue { value in
                // check that all operations executed
                XCTAssertEqual(value.count, 100)
                
                // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
                XCTAssert(Array(1 ... 100).allSatisfy(value.contains))
                
                dataVerificationExp.fulfill()
            }
        }
        
        op.start()
        
        wait(for: [completionBlockExp, dataVerificationExp], timeout: 1)
        
        XCTAssertEqual(op.value.count, 100)
        XCTAssert(Array(1 ... 100).allSatisfy(op.value.contains))
        
        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Test as a standalone operation. Do not run it.
    func testOp_concurrentAutomatic_NotRun() {
        let op = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        completionBlockExp.isInverted = true
        
        let dataVerificationExp = expectation(description: "Data Verification")
        dataVerificationExp.isInverted = true
        
        for val in 1 ... 100 {
            op.addOperation { $0.withValue { $0.append(val) } }
        }
        
        op.setCompletionBlock { v in
            completionBlockExp.fulfill()
            
            v.withValue { value in
                // check that all operations executed
                XCTAssertEqual(value.count, 100)
                
                // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
                XCTAssert(Array(1 ... 100).allSatisfy(value.contains))
                
                dataVerificationExp.fulfill()
            }
        }
        
        wait(for: [completionBlockExp, dataVerificationExp], timeout: 1)
        
        // state
        XCTAssertFalse(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Standalone operation, concurrent threading queue mode. Run it.
    func testOp_concurrentSpecificMax_Run() {
        let op = AtomicBlockOperation(
            type: .concurrent(max: 10),
            initialMutableValue: [Int]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        let dataVerificationExp = expectation(description: "Data Verification")
        
        let atomicBlockCompletedExp = expectation(description: "AtomicBlockOperation Completed")
        
        for val in 1 ... 100 {
            op.addOperation { $0.withValue { $0.append(val) } }
        }
        
        op.setCompletionBlock { v in
            completionBlockExp.fulfill()
            
            v.withValue { value in
                // check that all operations executed
                XCTAssertEqual(value.count, 100)
                
                // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
                XCTAssert(Array(1 ... 100).allSatisfy(value.contains))
                
                dataVerificationExp.fulfill()
            }
        }
        
        DispatchQueue.global().async {
            op.start()
            atomicBlockCompletedExp.fulfill()
        }
        
        wait(for: [completionBlockExp, dataVerificationExp, atomicBlockCompletedExp], timeout: 1)
        
        XCTAssertEqual(op.value.count, 100)
        XCTAssert(Array(1 ... 100).allSatisfy(op.value.contains))
        
        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Test in the context of an OperationQueue. Run is implicit.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testOp_concurrentAutomatic_Queue() {
        let opQ = OperationQueue()
                
        let op = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int]()
        )
        
        // test default qualityOfService to check baseline state
        XCTAssertEqual(op.qualityOfService, .default)
        
        op.qualityOfService = .userInitiated
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        let dataVerificationExp = expectation(description: "Data Verification")
        
        for val in 1 ... 100 {
            op.addOperation { v in
                // QoS should be inherited from the AtomicBlockOperation QoS
                XCTAssertEqual(Thread.current.qualityOfService, .userInitiated)
                
                // add value to array
                v.withValue { $0.append(val) }
            }
        }
        
        op.setCompletionBlock { v in
            completionBlockExp.fulfill()
            
            v.withValue { value in
                // check that all operations executed
                XCTAssertEqual(value.count, 100)
                
                // this happens to be in serial order even though we are using concurrent threads and no operation dependencies are being used
                XCTAssert(Array(1 ... 100).allSatisfy(value.contains))
                
                dataVerificationExp.fulfill()
            }
        }
        
        // must manually increment for OperationQueue
        opQ.progress.totalUnitCount += 1
        // queue automatically starts the operation once it's added
        opQ.addOperation(op)
        
        wait(for: [completionBlockExp, dataVerificationExp], timeout: 1)
        
        // state
        XCTAssertEqual(opQ.operationCount, 0)
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
    }
    
    /// Standalone operation, serial FIFO queue mode. Test that start() runs synchronously. Run it.
    func testOp_serialFIFO_SynchronousTest_Run() {
        let op = AtomicBlockOperation(
            type: .serialFIFO,
            initialMutableValue: [Int]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        for val in 1 ... 100 { // will take 1 second to complete
            op.addOperation { v in
                usleep(10000)
                v.withValue { $0.append(val) }
            }
        }
        
        op.setCompletionBlock { _ in
            completionBlockExp.fulfill()
        }
        
        op.start()
        
        // check that all operations executed and they are in serial FIFO order
        XCTAssertEqual(op.value, Array(1 ... 100))
        
        // state
        XCTAssertTrue(op.isFinished)
        XCTAssertFalse(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        
        wait(for: [completionBlockExp], timeout: 2)
    }
    
    /// Test a `AtomicBlockOperation` that enqueues multiple `AtomicBlockOperation`s and ensure data mutability works as expected.
    func testNested() {
        let mainOp = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int: [Int]]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        var mainVal: [Int: [Int]] = [:]
        
        for keyNum in 1 ... 10 {
            mainOp.addOperation { v in
                let subOp = AtomicBlockOperation(
                    type: .concurrentAutomatic,
                    initialMutableValue: [Int]()
                )
                subOp.addOperation { v in
                    v.withValue { value in
                        for valueNum in 1 ... 200 {
                            value.append(valueNum)
                        }
                    }
                }
                
                subOp.start()
                
                v.withValue { value in
                    value[keyNum] = subOp.value
                }
            }
        }
        
        mainOp.setCompletionBlock { v in
            v.withValue { value in
                mainVal = value
            }
            
            completionBlockExp.fulfill()
        }
        
        mainOp.start()
        
        wait(for: [completionBlockExp], timeout: 5)
        
        // state
        XCTAssertTrue(mainOp.isFinished)
        XCTAssertFalse(mainOp.isCancelled)
        XCTAssertFalse(mainOp.isExecuting)
        
        XCTAssertEqual(mainVal.count, 10)
        XCTAssertEqual(mainVal.keys.sorted(), Array(1 ... 10))
        XCTAssert(mainVal.values.allSatisfy { $0.sorted() == Array(1 ... 200) })
    }
    
    func testNested_Cancel() {
        let mainOp = AtomicBlockOperation(
            type: .concurrentAutomatic,
            initialMutableValue: [Int: [Int]]()
        )
        
        let completionBlockExp = expectation(description: "Completion Block Called")
        
        var mainVal: [Int: [Int]] = [:]
        
        for keyNum in 1 ... 10 {
            let subOp = AtomicBlockOperation(
                type: .concurrentAutomatic,
                initialMutableValue: [Int]()
            )
            var refs: [Operation] = []
            for valueNum in 1 ... 20 {
                let ref = subOp.addInteractiveOperation { op, v in
                    if op.mainShouldAbort() { return }
                    usleep(200_000)
                    v.withValue { value in
                        value.append(valueNum)
                    }
                }
                refs.append(ref)
            }
            
            subOp.addOperation { [weak mainOp] v in
                let getVal: [Int] = v.withValue { $0 }
                mainOp?.withValue { mainValue in
                    mainValue[keyNum] = getVal
                }
            }
            
            mainOp.addOperation(subOp)
        }
        
        mainOp.setCompletionBlock { v in
            v.withValue { value in
                mainVal = value
            }
            
            completionBlockExp.fulfill()
        }
        
        // must run start() async in order to cancel it, since
        // the operation is synchronous and will complete before we
        // can call cancel() if start() is run in-thread
        DispatchQueue.global().async {
            mainOp.start()
        }
        usleep(100_000)
        mainOp.cancel()
        
        wait(for: [completionBlockExp], timeout: 1)
        
        // XCTAssertEqual(mainOp.operationQueue.operationCount, 0)
        
        // state
        XCTAssertTrue(mainOp.isFinished)
        XCTAssertTrue(mainOp.isCancelled)
        XCTAssertFalse(
            mainOp
                .isExecuting
        ) // TODO: technically this should be true, but it gets set to false when the completion method gets called even if async code is still running
        
        let expectedArray = (1 ... 10).reduce(into: [Int: [Int]]()) {
            $0[$1] = Array(1 ... 200)
        }
        XCTAssertNotEqual(mainVal, expectedArray)
    }
    
    /// Ensure that nested progress objects successfully result in the topmost queue calling statusHandler at every increment of all progress children at every level.
    func testProgress() {
        // TODO: This test is flakey. Sometimes it succeeds and sometimes it fails, randomly. Perhaps points to issues with the code and not the test.
        
        class AtomicOperationQueueProgressTest {
            var statuses: [OperationQueueStatus] = []
            
            let mainOp = AtomicOperationQueue(
                type: .serialFIFO,
                qualityOfService: .default,
                initiallySuspended: true,
                resetProgressWhenFinished: true,
                initialMutableValue: 0
            )
            
            init() {
                mainOp.statusHandler = { newStatus, oldStatus in
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
        
        func runTest() {
            // 5 ops, each with 2 ops, each with 2 units of progress.
            // should equate to 20 total main progress updates 5% apart
            for _ in 1 ... 5 {
                let subOp = AtomicBlockOperation(
                    type: .serialFIFO,
                    label: "Top",
                    initialMutableValue: 0
                )
                
                for subOpNum in 1 ... 2 {
                    subOp.addInteractiveOperation(label: "Sub\(subOpNum)")
                        { operation, atomicValue in
                            operation.progress.totalUnitCount = 2
                        
                            operation.progress.completedUnitCount = 1
                            operation.progress.completedUnitCount = 2
                        }
                }
                
                qTest.mainOp.addOperation(subOp)
            }
            
            qTest.mainOp.isSuspended = false
            
            wait(for: qTest.mainOp.status, equals: .idle, timeout: 5.0)
        }
        
        let runExp = expectation(description: "Test Run")
        DispatchQueue.global().async {
            runTest()
            runExp.fulfill()
        }
        wait(for: [runExp], timeout: 8.0)
        
        // remove sequential duplicates in order to test, since operations
        // completing will trigger a statusHandler callback when labels
        // change even if progress percentage has not changed
        let reducedStatusFC = qTest.statuses
            .convertedToTestableFractionCompleted()
            .removingSequentialDuplicates()
        
        guard reducedStatusFC.count == 23 else {
            XCTFail("Count was expected to be 23 but was \(reducedStatusFC.indices.count) instead.")
            return
        }
        
        XCTAssertEqual(reducedStatusFC[00], .idle)
        XCTAssertEqual(reducedStatusFC[01], .paused)
        XCTAssertEqual(reducedStatusFC[02], .inProgress(fractionCompleted: 0.00))
        XCTAssertEqual(reducedStatusFC[03], .inProgress(fractionCompleted: 0.05))
        XCTAssertEqual(reducedStatusFC[04], .inProgress(fractionCompleted: 0.10))
        XCTAssertEqual(reducedStatusFC[05], .inProgress(fractionCompleted: 0.15))
        XCTAssertEqual(reducedStatusFC[06], .inProgress(fractionCompleted: 0.20))
        XCTAssertEqual(reducedStatusFC[07], .inProgress(fractionCompleted: 0.25))
        XCTAssertEqual(reducedStatusFC[08], .inProgress(fractionCompleted: 0.30))
        XCTAssertEqual(reducedStatusFC[09], .inProgress(fractionCompleted: 0.35))
        XCTAssertEqual(reducedStatusFC[10], .inProgress(fractionCompleted: 0.40))
        XCTAssertEqual(reducedStatusFC[11], .inProgress(fractionCompleted: 0.45))
        XCTAssertEqual(reducedStatusFC[12], .inProgress(fractionCompleted: 0.50))
        XCTAssertEqual(reducedStatusFC[13], .inProgress(fractionCompleted: 0.55))
        XCTAssertEqual(reducedStatusFC[14], .inProgress(fractionCompleted: 0.60))
        XCTAssertEqual(reducedStatusFC[15], .inProgress(fractionCompleted: 0.65))
        XCTAssertEqual(reducedStatusFC[16], .inProgress(fractionCompleted: 0.70))
        XCTAssertEqual(reducedStatusFC[17], .inProgress(fractionCompleted: 0.75))
        XCTAssertEqual(reducedStatusFC[18], .inProgress(fractionCompleted: 0.80))
        XCTAssertEqual(reducedStatusFC[19], .inProgress(fractionCompleted: 0.85))
        XCTAssertEqual(reducedStatusFC[20], .inProgress(fractionCompleted: 0.90))
        XCTAssertEqual(reducedStatusFC[21], .inProgress(fractionCompleted: 0.95))
        XCTAssertEqual(reducedStatusFC[22], .idle)
       
        // TODO: probably shouldn't test inProgress description since it's brittle;
        // TODO: it uses localizedDescription which may not always be English
        
        // remove sequential duplicates in order to test, since operations
        // completing will trigger a statusHandler callback when labels
        // change even if progress percentage has not changed
        let reducedStatusDesc = qTest.statuses
            .convertedToTestableDescription()
            .removingSequentialDuplicates()
        
        XCTAssertEqual(reducedStatusDesc[00], .idle)
        XCTAssertEqual(reducedStatusDesc[01], .paused)
        XCTAssertEqual(reducedStatusDesc[02], .inProgress(description: "0% completed"))
        XCTAssertEqual(reducedStatusDesc[03], .inProgress(description: "5% completed"))
        XCTAssertEqual(reducedStatusDesc[04], .inProgress(description: "10% completed"))
        XCTAssertEqual(reducedStatusDesc[05], .inProgress(description: "15% completed"))
        XCTAssertEqual(reducedStatusDesc[06], .inProgress(description: "20% completed"))
        XCTAssertEqual(reducedStatusDesc[07], .inProgress(description: "25% completed"))
        XCTAssertEqual(reducedStatusDesc[08], .inProgress(description: "30% completed"))
        XCTAssertEqual(reducedStatusDesc[09], .inProgress(description: "35% completed"))
        XCTAssertEqual(reducedStatusDesc[10], .inProgress(description: "40% completed"))
        XCTAssertEqual(reducedStatusDesc[11], .inProgress(description: "45% completed"))
        XCTAssertEqual(reducedStatusDesc[12], .inProgress(description: "50% completed"))
        XCTAssertEqual(reducedStatusDesc[13], .inProgress(description: "55% completed"))
        XCTAssertEqual(reducedStatusDesc[14], .inProgress(description: "60% completed"))
        XCTAssertEqual(reducedStatusDesc[15], .inProgress(description: "65% completed"))
        XCTAssertEqual(reducedStatusDesc[16], .inProgress(description: "70% completed"))
        XCTAssertEqual(reducedStatusDesc[17], .inProgress(description: "75% completed"))
        XCTAssertEqual(reducedStatusDesc[18], .inProgress(description: "80% completed"))
        XCTAssertEqual(reducedStatusDesc[19], .inProgress(description: "85% completed"))
        XCTAssertEqual(reducedStatusDesc[20], .inProgress(description: "90% completed"))
        XCTAssertEqual(reducedStatusDesc[21], .inProgress(description: "95% completed"))
        XCTAssertEqual(reducedStatusDesc[22], .idle)
        
    }
}
