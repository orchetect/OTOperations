//
//  Progress Extensions Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import XCTest
@testable import OTOperations

final class ProgressExtensions_Tests: XCTestCase {
    override func setUp() { super.setUp() }
    override func tearDown() { super.tearDown() }
    
    func testProgressParent_Nil() {
        let empty = Progress()
        
        XCTAssertNil(empty.parent)
    }
    
    func testProgressParent() {
        let master = Progress()
        let child1 = Progress(totalUnitCount: 10, parent: master, pendingUnitCount: 10)
        let child2 = Progress(totalUnitCount: 10, parent: master, pendingUnitCount: 10)
        
        XCTAssertEqual(child1.parent, master)
        XCTAssertEqual(child2.parent, master)
    }
    
    func testProgressChildren_Empty() {
        let empty = Progress()
        
        XCTAssertEqual(empty.children, [])
    }
    
    func testProgressChildren() {
        let master = Progress()
        let child1 = Progress(totalUnitCount: 10, parent: master, pendingUnitCount: 10)
        let child2 = Progress(totalUnitCount: 10, parent: master, pendingUnitCount: 10)
        
        XCTAssertEqual(master.children, [child1, child2])
    }
    
    func testParent_Memory() {
        class Foo {
            weak var master: Progress?
            weak var child1: Progress?
            weak var child2: Progress?
        }
        
        let foo = Foo()
        
        autoreleasepool {
            let strongMaster = Progress(totalUnitCount: 20)
            foo.master = strongMaster
            
            let child1 = Progress(totalUnitCount: 10, parent: strongMaster, pendingUnitCount: 10)
            foo.child1 = child1
            
            let child2 = Progress(totalUnitCount: 10, parent: strongMaster, pendingUnitCount: 10)
            foo.child2 = child2
            
            // just access the parent, we want to check that it doesn't create memory issues
            _ = child1.parent
            
            // complete the children
            child1.completedUnitCount = child1.totalUnitCount
            child2.completedUnitCount = child2.totalUnitCount
        }
        
        // ensure parent deallocates and has no strong references remaining in memory
        
        XCTAssertNil(foo.master)
        XCTAssertNil(foo.child1)
        XCTAssertNil(foo.child1?.parent)
        XCTAssertNil(foo.child2)
        XCTAssertNil(foo.child2?.parent)
    }
    
    func testChildren_Memory() {
        class Foo {
            var master: Progress!
            weak var child1: Progress?
            weak var child2: Progress?
        }
        
        var foo: Foo!
        weak var masterRef: Progress?
        
        autoreleasepool {
            foo = Foo()
            
            do {
                foo.master = Progress(totalUnitCount: 20)
                
                let child1 = Progress(totalUnitCount: 10, parent: foo.master, pendingUnitCount: 10)
                foo.child1 = child1
                
                let child2 = Progress(totalUnitCount: 10, parent: foo.master, pendingUnitCount: 10)
                foo.child2 = child2
            }
            
            // just access children, we want to check that it doesn't create memory issues
            _ = foo.master!.children
            
            // complete the children
            foo.child1!.completedUnitCount = foo.child1!.totalUnitCount
            foo.child2!.completedUnitCount = foo.child2!.totalUnitCount
        }
        
        // ensure parent deallocates and has no strong references remaining in memory
        
        XCTAssertNil(foo.child1)
        XCTAssertNil(foo.child1?.parent)
        XCTAssertNil(foo.child2)
        XCTAssertNil(foo.child2?.parent)
        
        masterRef = foo.master
        foo = nil
        
        XCTAssertNil(masterRef)
    }
    
    func testPurgeChildren() {
        class Foo {
            var master: Progress! = Progress(totalUnitCount: 20)
            weak var child1: Progress?
            weak var child2: Progress?
        }
        
        var foo: Foo!
        weak var masterRef: Progress?
        
        autoreleasepool {
            foo = Foo()
            
            let newChild1 = Progress(
                totalUnitCount: 10,
                parent: foo.master,
                pendingUnitCount: 10
            )
            foo.child1 = newChild1
            
            let newChild2 = Progress(
                totalUnitCount: 10,
                parent: foo.master,
                pendingUnitCount: 10
            )
            foo.child2 = newChild2
            
            XCTAssertNotNil(foo.child1)
            XCTAssertNotNil(foo.child2)
            
            // parent Progress holds strong reference to children until they are complete
            XCTAssertEqual(foo.master.children.count, 2)
            XCTAssertEqual(foo.master.children, [foo.child1, foo.child2])
            
            let strongChild1 = foo.child1!
            let strongChild2 = foo.child2!
            
            // manually remove children
            let purgedCount = foo.master.purgeChildren()
            
            XCTAssertEqual(purgedCount, 2)
            XCTAssertEqual(foo.master.children.count, 0)
            
            XCTAssertNil(strongChild1.parent)
            XCTAssertNil(strongChild2.parent)
        }
        
        // weak vars finally release after last strong ref disappears
        XCTAssertNil(foo.child1)
        XCTAssertNil(foo.child2)
        
        masterRef = foo.master
        foo = nil
        
        // check that the parent releases
        XCTAssertNil(masterRef)
    }
    
    func testPurgeLabelProgressChildren() {
        class Foo {
            var master: LabelProgress! = LabelProgress(totalUnitCount: 20)
            weak var child1: LabelProgress?
            weak var child2: LabelProgress?
        }
        
        var foo: Foo!
        weak var masterRef: LabelProgress?
        
        autoreleasepool {
            foo = Foo()
            
            let newChild1 = LabelProgress(totalUnitCount: 10)
            foo.master.addChild(newChild1, withPendingUnitCount: 10)
            foo.child1 = newChild1
            
            let newChild2 = LabelProgress(totalUnitCount: 10)
            foo.master.addChild(newChild2, withPendingUnitCount: 10)
            foo.child2 = newChild2
            
            XCTAssertNotNil(foo.child1)
            XCTAssertNotNil(foo.child2)
            
            // parent Progress holds strong reference to children until they are complete
            XCTAssertEqual(foo.master.children.count, 2)
            XCTAssertEqual(foo.master.children, [foo.child1, foo.child2])
            
            let strongChild1 = foo.child1!
            let strongChild2 = foo.child2!
            
            // manually remove children
            let purgedCount = foo.master.purgeLabelProgressChildren()
            
            XCTAssertEqual(purgedCount, 2)
            XCTAssertEqual(foo.master.children.count, 0)
            
            XCTAssertNil(strongChild1.parent)
            XCTAssertNil(strongChild2.parent)
        }
        
        // weak vars finally release after last strong ref disappears
        XCTAssertNil(foo.child1)
        XCTAssertNil(foo.child2)
        
        masterRef = foo.master
        foo = nil
        
        // check that the parent releases
        XCTAssertNil(masterRef)
    }
}
