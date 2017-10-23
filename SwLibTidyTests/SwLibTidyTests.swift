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
import CLibTidyEnum

class SwiftTests: XCTestCase {
    
    private var tdoc: TidyDoc?

    override func setUp() {
        super.setUp()
        tdoc = tidyCreate()!
    }
    
    
    override func tearDown() {
        tidyRelease( tdoc! )
        super.tearDown()
    }


    /* Many of our tests require Tidy to Tidy a file first. */
    func tidy( doc: TidyDoc, file: String, config: String? = nil) -> Swift.Bool {

        let testBundle = Bundle(for: type(of: self))

        if let config = config {
            if let file = testBundle.path(forResource: config, ofType: "conf") {
                let _ = tidyLoadConfig( doc, file )
            }
        }

        if let file = testBundle.path(forResource: file, ofType: "html") {
           let _ = tidyParseFile( doc, file )
        } else {
            return false
        }

        return true
    }


    /*************************************************************************
      In order to do anything at all with Tidy, we need an instance of a Tidy
      document (TidyDoc), and when we're done with it, we have to release it
      in order to free its memory and resources.

      Although the setUp() and tearDown() do this for every other unit test,
      this case demonstrates how to create and free a TidyDoc.

      - tidyCreate()
      - tidyRelease()
     *************************************************************************/
    func test_tidyCreate() {

        if let localDoc = tidyCreate() {
            tidyRelease( localDoc )
        } else {
            XCTAssert ( false, "Could not create a Tidy document." )
        }
    }


    /*************************************************************************
      If you are going to use Tidy's callbacks, then Tidy needs some context
      information so that when the callback occurs, your callback knows the
      where it originates. For example, you might set a reference to the
      instance of your class that is invoking Tidy.

      - tidySetAppData()
      - tidyGetAppData()
     *************************************************************************/
    func test_tidySetAppData_tidyGetAppData() {

        tidySetAppData( tdoc!, self )
        let gotObject = tidyGetAppData( tdoc! )
    
        XCTAssert( gotObject === self, "The object stored is not that same as the object retrieved." )
    }
    
    
    /*************************************************************************
      Tidy is able to report basic information about itself, such as its
      release date, its current version, and the platform for which is was
      compiled.

      - tidyReleaseDate()
      - tidyLibraryVersion()
      - tidyPlatform()
     *************************************************************************/
    func test_tidyReleaseInformation() {

        XCTAssert( tidyReleaseDate().hasPrefix("2017."), "The release date does not begin with 2017." )

        XCTAssert( tidyLibraryVersion().hasPrefix("5.5"), "The library version does not begin with 5.5." )

        XCTAssert( (tidyPlatform()?.hasPrefix("Apple"))!, "The platform does not begin with \"Apple\"" )
    }
    
    
    /*************************************************************************
      Tidy is able to use a configuration loaded from a configuration file,
      and so this case indicates how to load such a file which has been
      included in the bundle. We will judge that this operation is successful
      if one of the configuration values we loaded matches what we expect,
      which is different from the built-in default value.

      - tidyLoadConfig()
     *************************************************************************/
    func test_tidyLoadConfig() {

        let testBundle = Bundle(for: type(of: self))

        if let file = testBundle.path(forResource: "case-001", ofType: "conf") {
            let _ = tidyLoadConfig( tdoc!, file )
        }

        XCTAssert( tidyOptGetInt( tdoc!, TidyAccessibilityCheckLevel ) == 3, "Expected " )
    }


    /*************************************************************************
      Tidy, of course, has to be able to parse HTML from a variety of sources
      before clean and repair operations can take place, and before most
      operations can take place on a TidyDoc. Here we will demonstrate that
      parsing is successful via examining the tidyStatus() after parsing. In
      each case, the status should be 1, indicating that warnings were found,
      but not errors.

      - tidyStatus()
      - tidyParseString()
      - tidyParseFile()
     *************************************************************************/
    func test_tidyParseStuff() {

        let _ = tidyParseString( tdoc!, "<h1>Hello, world!</h2>" )

        XCTAssert( tidyStatus( tdoc! ) == 1, "Expected tidyStatus() == 1" )

        let testBundle = Bundle(for: type(of: self))

        if let file = testBundle.path(forResource: "case-001", ofType: "html") {
            let _ = tidyParseFile( tdoc!, file )
        }

        XCTAssert( tidyStatus( tdoc! ) == 1, "Expected tidyStatus() == 1" )
    }


    /*************************************************************************
      After parsing, Tidy makes available a lot of status information about
      the document it's parsed, such as error and warning counts and some
      general information.

      - tidyStatus()
      - tidyDetectedXhtml()
      - tidyDetectedGenericXml()
      - tidyErrorCount()
      - tidyWarningCount()
      - tidyAccessWarningCount()
      - tidyConfigErrorCount()
     *************************************************************************/
    func test_tidyStatusInformation() {

        XCTAssert( tidy( doc: tdoc!, file: "case-001", config: "case-001" ), "Could not locate the file for testing." )

        XCTAssert( tidyStatus( tdoc! ) == 1, "Expected tidyStatus() == 1" )

        XCTAssert( tidyDetectedXhtml( tdoc! ) == false, "Expected tidyDetectedXhtml() == false" )

        XCTAssert( tidyDetectedGenericXml( tdoc! ) == false, "Expected tidyDetectedGenericXml() == false" )

        XCTAssert( tidyErrorCount( tdoc! ) == 0, "Expected tidyErrorCount() == 0" )

        XCTAssert( tidyWarningCount( tdoc! ) == 3, "Expected tidyWarningCount() == 3" )

        XCTAssert( tidyAccessWarningCount( tdoc! ) == 4, "Expected tidyAccessWarningCount() == 4" )

        XCTAssert( tidyConfigErrorCount( tdoc! ) == 1, "Expected tidyConfigErrorCount() == 1" )
    }

}
