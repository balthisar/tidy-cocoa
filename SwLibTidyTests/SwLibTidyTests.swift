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
//import CLibTidy

class SwiftTests: XCTestCase {
    
    private var tdoc: TidyDoc?

    override func setUp() {
        super.setUp()
        tdoc = SwLibTidy.tidyCreate()!
    }
    
    
    override func tearDown() {
        SwLibTidy.tidyRelease( tdoc! )
        super.tearDown()
    }


    /* Many of our tests require Tidy to Tidy a file first. */
    func tidy( doc: TidyDoc, file: String, config: String? = nil) -> Swift.Bool {

        let testBundle = Bundle(for: type(of: self))

        if let config = config {
            if let file = testBundle.path(forResource: config, ofType: "conf") {
                let _ = SwLibTidy.tidyLoadConfig( doc, file )
            }
        }

        if let file = testBundle.path(forResource: file, ofType: "html") {
           let _ = SwLibTidy.tidyParseFile( doc, file )
        } else {
            return false
        }

        return true
    }


    /*************************************************************************
      Although the setUp() and tearDown() do this for every test, let's test
      it for the sake of coverage.
     *************************************************************************/
    func test_tidyCreate() {

        if let localDoc = SwLibTidy.tidyCreate() {
            SwLibTidy.tidyRelease( localDoc )
        } else {
            XCTAssert ( false, "Could not create a Tidy document." )
        }
    }


    /*************************************************************************
      Ensure that we can set and get Tidy's app data properly. Proper storage
      is required so that we can properly execute Tidy's callbacks, if used.
      - tidySetAppData()
      - tidyGetAppData()
     *************************************************************************/
    func test_tidySetAppData_tidyGetAppData() {

        SwLibTidy.tidySetAppData( tdoc!, self )
        let gotObject = SwLibTidy.tidyGetAppData( tdoc! )
    
        XCTAssert( gotObject === self, "The object stored is not that same as the object retrieved." )
    }
    
    
    /*************************************************************************
      Test basic function:
      - tidyReleaseDate()
      - tidyLibraryVersion()
      - tidyPlatform()
     *************************************************************************/
    func test_tidyReleaseInformation() {

        XCTAssert( SwLibTidy.tidyReleaseDate().hasPrefix("2017."), "The release date does not begin with 2017." )

        XCTAssert( SwLibTidy.tidyLibraryVersion().hasPrefix("5.5"), "The library version does not begin with 5.5." )

        XCTAssert( (SwLibTidy.tidyPlatform()?.hasPrefix("Apple"))!, "The platform does not begin with \"Apple\"" )
    }
    
    
    /*************************************************************************
      Test basic function:
      - tidyStatus()
      - tidyDetectedXhtml()
      - tidyDetectedGenericXml()
      - tidyErrorCount()
      - tidyWarningCount()
      - tidyAccessWarningCount()
      - tidyConfigErrorCount()
      - tidyLoadConfig()
     *************************************************************************/
    func test_tidyStatusInformation() {

        XCTAssert( tidy( doc: tdoc!, file: "case-001", config: "case-001" ), "Could not locate the file for testing." )

        XCTAssert( SwLibTidy.tidyStatus( tdoc! ) == 1, "Expected tidyStatus() == 1" )

        XCTAssert( SwLibTidy.tidyDetectedXhtml( tdoc! ) == false, "Expected tidyDetectedXhtml() == false" )

        XCTAssert( SwLibTidy.tidyDetectedGenericXml( tdoc! ) == false, "Expected tidyDetectedGenericXml() == false" )

        XCTAssert( SwLibTidy.tidyErrorCount( tdoc! ) == 0, "Expected tidyErrorCount() == 0" )

        XCTAssert( SwLibTidy.tidyWarningCount( tdoc! ) == 3, "Expected tidyWarningCount() == 3" )

        XCTAssert( SwLibTidy.tidyAccessWarningCount( tdoc! ) == 4, "Expected tidyAccessWarningCount() == 4" )

        XCTAssert( SwLibTidy.tidyConfigErrorCount( tdoc! ) == 1, "Expected tidyConfigErrorCount() == 1" )

        /*
         Prove that we loaded a config file by checking the value of
         TidyAccessibilityCheckLevel, thus, tidyLoadConfig() worked.
         */

        let x: TidyOptionId = TidyVertSpace // how to re-export this symbol without needing the CLibTidy?
        XCTAssert( SwLibTidy.tidyOptGetInt( tdoc!, x ) == 3, "Expected " )


    }

}
