//
//  LabelProgress Tests.swift
//  OTOperations • https://github.com/orchetect/OTOperations
//  © 2022 Steffan Andrews • Licensed under MIT License
//

import XCTest
@testable import OTOperations

final class LabelProgress_Tests: XCTestCase {
    override func setUp() { super.setUp() }
    override func tearDown() { super.tearDown() }
    
    func testInit() {
        let main = LabelProgress()
        
        XCTAssertEqual(main.parent, nil)
        XCTAssertEqual(main.children, [])
        XCTAssertEqual(main.label, nil)
    }
    
    func testInit_totalUnitCount() {
        let main = LabelProgress(totalUnitCount: 1)
        
        XCTAssertEqual(main.parent, nil)
        XCTAssertEqual(main.children, [])
        XCTAssertEqual(main.label, nil)
        XCTAssertEqual(main.totalUnitCount, 1)
    }
    
    func testInit_totalUnitCount_label() {
        let main = LabelProgress(totalUnitCount: 1, label: "A label")
        
        XCTAssertEqual(main.parent, nil)
        XCTAssertEqual(main.children, [])
        XCTAssertEqual(main.label, "A label")
        XCTAssertEqual(main.totalUnitCount, 1)
    }
    
    func testInit_parent_userInfo_label() {
        let main = LabelProgress(totalUnitCount: 1)
        let childProg = LabelProgress(parent: nil, userInfo: nil, label: "A label")
        
        XCTAssertEqual(main.children, [])
        XCTAssertEqual(main.label, nil)
        
        XCTAssertEqual(childProg.parent, nil)
        XCTAssertEqual(childProg.label, "A label")
    }
    
    func testLabel_NoChildren() {
        let prog = LabelProgress()
        
        XCTAssertNil(prog.label)
        XCTAssertNil(prog.combinedLabel)
        XCTAssertNil(prog.deepLabel)
        
        prog.label = "Main"
        XCTAssertEqual(prog.label, "Main")
        XCTAssertEqual(prog.combinedLabel, "Main")
        XCTAssertEqual(prog.deepLabel, "Main")
        
        prog.label = "" // sets nil if string is empty
        XCTAssertNil(prog.label)
        XCTAssertNil(prog.combinedLabel)
        XCTAssertNil(prog.deepLabel)
        
        prog.label = "Main"
        XCTAssertEqual(prog.label, "Main")
        XCTAssertEqual(prog.combinedLabel, "Main")
        XCTAssertEqual(prog.deepLabel, "Main")
        
        prog.label = nil
        XCTAssertNil(prog.label)
        XCTAssertNil(prog.combinedLabel)
        XCTAssertNil(prog.deepLabel)
    }
    
    func testLabelNil_ChildHasLabelBeforeAddingToParent() {
        let main = LabelProgress()
        
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        let ch1 = LabelProgress()
        ch1.label = "Child1"
        main.totalUnitCount += 1
        main.addChild(ch1, withPendingUnitCount: 1)
        
        XCTAssertNil(main.label)
        XCTAssertEqual(main.combinedLabel, "Child1")
        XCTAssertEqual(main.deepLabel, "Child1")
        
        main.label = "Main"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main - Child1")
        XCTAssertEqual(main.deepLabel, "Main - Child1")
        
        ch1.label = nil
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main")
        XCTAssertEqual(main.deepLabel, "Main")
    }
    
    func testLabelNil_ChildNilButSetChildLabelAfterAddingToParent() {
        let main = LabelProgress()
        
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        
        let ch1 = LabelProgress()
        main.totalUnitCount += 1
        main.addChild(ch1, withPendingUnitCount: 1)
        
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        main.label = "Main"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main")
        XCTAssertEqual(main.deepLabel, "Main")
        
        ch1.label = "Child1"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main - Child1")
        XCTAssertEqual(main.deepLabel, "Main - Child1")
        
        ch1.label = nil
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main")
        XCTAssertEqual(main.deepLabel, "Main")
    }
    
    func testLabelNil_MultipleChildren() {
        let main = LabelProgress()
        
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        let ch1 = LabelProgress()
        main.totalUnitCount += 1
        main.addChild(ch1, withPendingUnitCount: 1)
        
        let ch2 = LabelProgress()
        main.totalUnitCount += 1
        main.addChild(ch2, withPendingUnitCount: 1)
        
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        main.label = "Main"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main")
        XCTAssertEqual(main.deepLabel, "Main")
        
        ch1.label = "Child1"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main - Child1")
        XCTAssertEqual(main.deepLabel, "Main - Child1")
        
        ch2.label = "Child2"
        XCTAssertEqual(main.label, "Main")
        XCTAssertEqual(main.combinedLabel, "Main - Child1, Child2")
        XCTAssertEqual(main.deepLabel, "Main - Child1, Child2")
    }
    
    func testLabelNil_NestedChildren() {
        let main = LabelProgress()
        
        // main: initial state
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        let ch1A = LabelProgress()
        main.totalUnitCount += 1
        main.addChild(ch1A, withPendingUnitCount: 1)
        
        let ch1B = LabelProgress()
        main.totalUnitCount += 1
        main.addChild(ch1B, withPendingUnitCount: 1)
        
        let ch2 = LabelProgress()
        ch1A.totalUnitCount += 1
        ch1A.addChild(ch2, withPendingUnitCount: 1)
        
        let ch3 = LabelProgress()
        ch2.totalUnitCount += 1
        ch2.addChild(ch3, withPendingUnitCount: 1)
        
        let ch4 = LabelProgress()
        ch3.totalUnitCount += 1
        ch3.addChild(ch4, withPendingUnitCount: 1)
        
        // main: state after adding nested children
        XCTAssertNil(main.label)
        XCTAssertNil(main.combinedLabel)
        XCTAssertNil(main.deepLabel)
        
        main.label = "Main"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(main.combinedLabel, "Main")
        XCTAssertEqual(main.deepLabel,     "Main")
        
        ch1A.label = "C1A"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(ch1A.label,         "C1A")
        XCTAssertEqual(main.combinedLabel, "Main - C1A")
        XCTAssertEqual(main.deepLabel,     "Main - C1A")
        XCTAssertEqual(ch1A.combinedLabel, "C1A")
        XCTAssertEqual(ch1A.deepLabel,     "C1A")
        
        ch1B.label = "C1B"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(ch1A.label,         "C1A")
        XCTAssertEqual(ch1B.label,         "C1B")
        XCTAssertEqual(main.combinedLabel, "Main - C1A, C1B")
        XCTAssertEqual(main.deepLabel,     "Main - C1A, C1B")
        XCTAssertEqual(ch1A.combinedLabel, "C1A")
        XCTAssertEqual(ch1A.deepLabel,     "C1A")
        XCTAssertEqual(ch1B.combinedLabel, "C1B")
        XCTAssertEqual(ch1B.deepLabel,     "C1B")
        
        ch2.label = "C2"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(ch1A.label,         "C1A")
        XCTAssertEqual(ch1B.label,         "C1B")
        XCTAssertEqual(ch2.label,          "C2")
        XCTAssertEqual(main.combinedLabel, "Main - C1A, C1B")
        XCTAssertEqual(main.deepLabel,     "Main - C1A - C2, C1B")
        XCTAssertEqual(ch1A.combinedLabel, "C1A - C2")
        XCTAssertEqual(ch1A.deepLabel,     "C1A - C2")
        XCTAssertEqual(ch1B.combinedLabel, "C1B")
        XCTAssertEqual(ch1B.deepLabel,     "C1B")
        XCTAssertEqual(ch2.combinedLabel,  "C2")
        XCTAssertEqual(ch2.deepLabel,      "C2")
        
        ch3.label = "C3"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(ch1A.label,         "C1A")
        XCTAssertEqual(ch1B.label,         "C1B")
        XCTAssertEqual(ch2.label,          "C2")
        XCTAssertEqual(ch3.label,          "C3")
        XCTAssertEqual(main.combinedLabel, "Main - C1A, C1B")
        XCTAssertEqual(main.deepLabel,     "Main - C1A - C2 - C3, C1B")
        XCTAssertEqual(ch1A.combinedLabel, "C1A - C2")
        XCTAssertEqual(ch1A.deepLabel,     "C1A - C2 - C3")
        XCTAssertEqual(ch1B.combinedLabel, "C1B")
        XCTAssertEqual(ch1B.deepLabel,     "C1B")
        XCTAssertEqual(ch2.combinedLabel,  "C2 - C3")
        XCTAssertEqual(ch2.deepLabel,      "C2 - C3")
        XCTAssertEqual(ch3.combinedLabel,  "C3")
        XCTAssertEqual(ch3.deepLabel,      "C3")
        
        ch4.label = "C4"
        XCTAssertEqual(main.label,         "Main")
        XCTAssertEqual(ch1A.label,         "C1A")
        XCTAssertEqual(ch1B.label,         "C1B")
        XCTAssertEqual(ch2.label,          "C2")
        XCTAssertEqual(ch3.label,          "C3")
        XCTAssertEqual(ch4.label,          "C4")
        XCTAssertEqual(main.combinedLabel, "Main - C1A, C1B")
        XCTAssertEqual(main.deepLabel,     "Main - C1A - C2 - C3 - C4, C1B")
        XCTAssertEqual(ch1A.combinedLabel, "C1A - C2")
        XCTAssertEqual(ch1A.deepLabel,     "C1A - C2 - C3 - C4")
        XCTAssertEqual(ch1B.combinedLabel, "C1B")
        XCTAssertEqual(ch1B.deepLabel,     "C1B")
        XCTAssertEqual(ch2.combinedLabel,  "C2 - C3")
        XCTAssertEqual(ch2.deepLabel,      "C2 - C3 - C4")
        XCTAssertEqual(ch3.combinedLabel,  "C3 - C4")
        XCTAssertEqual(ch3.deepLabel,      "C3 - C4")
        XCTAssertEqual(ch4.combinedLabel,  "C4")
        XCTAssertEqual(ch4.deepLabel,      "C4")
    }
}
