//
//  Progress Extensions Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//

#if shouldTestCurrentPlatform

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
    
    func testPurgeChildren() {
        
        class SomeClass { }
        
        class Foo {
            var master: Progress! = Progress(totalUnitCount: 20)
            weak var child1: Progress?
            weak var child2: Progress?
            weak var someClass: SomeClass?
        }
        
        var foo: Foo!
        weak var captureMaster: Progress?
        
        autoreleasepool {
            foo = Foo()
            
            do {
                let newChild1 = Progress(totalUnitCount: 10,
                                         parent: foo.master,
                                         pendingUnitCount: 10)
                foo.child1 = newChild1
                
                let newChild2 = Progress(totalUnitCount: 10,
                                         parent: foo.master,
                                         pendingUnitCount: 10)
                foo.child2 = newChild2
                
                let someClass = SomeClass()
                foo.someClass = someClass
            }
            
            XCTAssertNotNil(foo.child1)
            XCTAssertNotNil(foo.child2)
            
            // parent Progress holds strong reference to children until they are complete
            XCTAssertEqual(foo.master.children.count, 2)
            XCTAssertEqual(foo.master.children, [foo.child1, foo.child2])
            
            do {
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
            XCTAssertNil(foo.someClass)
            
            captureMaster = foo.master
            foo.master = nil
        }
        
        // check that the parent releases
        XCTAssertNil(captureMaster)
        
    }
    
}

#endif
