//
//  SwLibTidyTests_Basic.swift
//  SwLibTidyTests
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import XCTest
@testable import SwLibTidy

class SwLibTidyTests_Basic: XCTestCase {
    
    private var tdoc: TidyDoc?
    
    
    override func setUp() {
        
        super.setUp()
        
        tdoc = tidyCreate()
    }
    
    
    override func tearDown() {
        
        if let tdoc = tdoc {
            tidyRelease(tdoc)
        }

        super.tearDown()
    }
    
    // tidySetAppData()
    // tidyGetAppData()
    // Ensure that we can set and get Tidy's a
    func testSetAndGetAppData() {
        
        tidySetAppData(tdoc!, self)
        let gotObject = tidyGetAppData(tdoc!)
    
        XCTAssert(gotObject === self, "The object stored is not that same as the object retrieved.")
    }
    
    
    // tidyReleaseDate()
    func test_tidyReleaseDate() {
        let str = tidyReleaseDate()
        print(str)
        XCTAssert(str.hasPrefix("2017."), "The release date does not begin with 2017.")
    }
    
    
    // tidyLibraryVersion
    func test_tidyLibraryVersion() {
        let str = tidyLibraryVersion()
        print(str)
        XCTAssert(str.hasPrefix("5.5"), "The library version does not begin with 5.5.")
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
