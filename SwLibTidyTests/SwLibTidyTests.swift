/******************************************************************************

    SwLibTidyTests.swift
    Basic tests of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Created by Jim Derry on 8/10/17.
    Copyright © 2017 Jim Derry. All rights reserved.

 ******************************************************************************/

import XCTest
@testable import SwLibTidy

class SwiftTests: XCTestCase {
    
    private var tdoc: TidyDoc?
    private let delimiter = "=-=-=-=-=-=-=-=-=-=-"

    override func setUp() {
        super.setUp()
        tdoc = tidyCreate()
        print(delimiter)
    }
    
    
    override func tearDown() {
        print(delimiter)
        if let tdoc = tdoc {
            tidyRelease(tdoc)
        }

        super.tearDown()
    }

    /**
     Ensure that we can set and get Tidy's app data properly. Proper storage
     is required so that we can properly execute Tidy's callbacks, if used.
     - tidySetAppData()
     - tidyGetAppData()
     */
    func testSetAndGetAppData() {

        guard let tdoc = tdoc else { return }

        tidySetAppData(tdoc, self)
        let gotObject = tidyGetAppData(tdoc)
    
        XCTAssert(gotObject === self, "The object stored is not that same as the object retrieved.")
    }
    
    
    /**
     Test basic function:
     - tidyReleaseDate()
     */
    func test_tidyReleaseDate() {
        let str = tidyReleaseDate()
        print(str)
        XCTAssert(str.hasPrefix("2017."), "The release date does not begin with 2017.")
    }
    
    
    /**
     Test basic function:
     - tidyLibraryVersion()
     */
    func test_tidyLibraryVersion() {
        let str = tidyLibraryVersion()
        print(str)
        XCTAssert(str.hasPrefix("5.5"), "The library version does not begin with 5.5.")
    }

}
