/******************************************************************************

    SwLibTidyTests.swift
    Basic tests of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    Given that tidy-html5 doesn't have its own unit tests, this suite also
    manages to test nearly all of CLibTidy's public API.
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


class SwLibTidyTests: XCTestCase {

    /* Common Strings */
    let TidyCreateFailed = "tidyCreate() failed, which is highly unusual."

    /* Simplify access to the test project's bundle. */
    private var testBundle: Bundle {
        return Bundle(for: type(of: self))
    }

    /* Simplify access to the test project's sample config file. */
    private var testConfig: String? {
        if let resource = testBundle.path(forResource: "case-001", ofType: "conf") {
            return resource
        } else {
            /* Fail HERE, because this is a bundle issue, not a test case issue. */
            self.continueAfterFailure = false
            XCTFail( "The sample configuration file appears to be missing from the bundle." )
            return ""
        }
    }

    /* Simplify access to the test project's sample HTML file. */
    private var testHtml: String? {
        if let resource = testBundle.path(forResource: "case-001", ofType: "html") {
            return resource
        } else {
            continueAfterFailure = false
            /* Fail HERE, because this is a bundle issue, not a test case issue. */
            XCTFail( "The sample HTML file appears to be missing from the bundle." )
            return ""
        }
    }


    /*
     Many of our tests require Tidy to Tidy a file first. This will tidy
     the included sample file using the given TidyDoc, optionally using
     the included sample configuration file.
     */
    private func tidySample( doc: TidyDoc, useConfig: Swift.Bool = false ) -> Swift.Bool {

        guard
            let config = testConfig,
            let html = testHtml
        else { return false }

        if useConfig {
            let _ = tidyLoadConfig( doc, config )
        }

           let _ = tidyParseFile( doc, html )

        return true
    }

    // MARK: - Test Cases
    /*************************************************************************
      In order to do anything at all with Tidy, we need an instance of a Tidy
      document (TidyDoc), and when we're done with it, we have to release it
      in order to free its memory and resources.

      - tidyCreate()
      - tidyRelease()
     *************************************************************************/
    func test_tidyCreate() {

        if let tdoc: TidyDoc = tidyCreate() {
            tidyRelease( tdoc )
        } else {
            XCTFail( TidyCreateFailed )
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        tidySetAppData( tdoc, self )
        let gotObject = tidyGetAppData( tdoc )
    
        XCTAssert( gotObject === self, "The object stored is not that same as the object retrieved." )

        tidyRelease( tdoc )
    }
    
    
    /*************************************************************************
      Tidy is able to report basic information about itself, such as its
      release date, its current version, and the platform for which is was
      compiled.

      Note that this test is fragile, as it depends on the library date and
      version numbers.

      - tidyReleaseDate()
      - tidyLibraryVersion()
      - tidyPlatform()
     *************************************************************************/
    func test_tidyReleaseInformation() {

        let expectedDate = "2017."
        let expectedVers = "5.5"
        let expectedPlat = "Apple"

        XCTAssert( tidyReleaseDate().hasPrefix(expectedDate), "The release date does not begin with '\(expectedDate)'." )

        XCTAssert( tidyLibraryVersion().hasPrefix(expectedVers), "The library version does not begin with '\(expectedVers)'." )

        XCTAssert( (tidyPlatform()?.hasPrefix(expectedPlat))!, "The platform does not begin with '\(expectedPlat)'." )
    }
    
    
    /*************************************************************************
      Tidy is able to use a configuration loaded from a configuration file,
      and so this case indicates how to load such a file which has been
      included in the bundle. We will judge that this operation is successful
      if one of the configuration values we loaded matches what we expect,
      which is different from the built-in default value.

      Because we're also testing the encoding version of the configuration
      loader, we'll opportunistically test tidyOptResetAllToDefault().

      - tidyLoadConfig()
      - tidyLoadConfigEnc()
      - tidyOptResetAllToDefault()
     *************************************************************************/
    func test_tidyLoadConfig() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        var result: UInt

        if let file = testConfig {

            let _ = tidyLoadConfig( tdoc, file )
            result = tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel )
            XCTAssert( result == 3, "Expected 3, but got \(result)." )

            let _ = tidyOptResetAllToDefault( tdoc )
            result = tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel )
            XCTAssert( result == 0, "Expected 0, but got \(result)." )

            let _ = tidyLoadConfigEnc( tdoc, file, "ascii")
            result = tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel )
            XCTAssert( result == 3, "Expected 3, but got \(result)." )
        }

        tidyRelease( tdoc )
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
      - tidyParseStdin()
     *************************************************************************/
    func test_tidyParse() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* We'll throw away the return value, and check tidyStatus(). */
        let _ = tidyParseString( tdoc, "<h1>Hello, world!</h2>" )
        var result = tidyStatus( tdoc )
        XCTAssert( result == 1, "Expected tidyStatus() == 1, but it was \(result)." )

        /* Use the return value directly. */
        if let file = testHtml {
            result = tidyParseFile( tdoc, file )
        }
        XCTAssert( result == 1, "Expected tidyStatus() == 1, but it was \(result)." )

        /* Redirect a file to stdin, so we can test tidyParseStdin(). */
        if let file = testHtml {
            freopen( file, "r", stdin )
            result = tidyParseStdin( tdoc )
            XCTAssert( result == 1, "Expected tidyStatus() == 1, but it was \(result)." )
        }

        tidyRelease( tdoc )
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        XCTAssert( tidySample( doc: tdoc, useConfig: true ), "tidySample() failed for some reason." )

        XCTAssert( tidyStatus( tdoc ) == 1, "Expected tidyStatus() == 1" )

        XCTAssert( tidyDetectedXhtml( tdoc ) == false, "Expected tidyDetectedXhtml() == false" )

        XCTAssert( tidyDetectedGenericXml( tdoc ) == false, "Expected tidyDetectedGenericXml() == false" )

        XCTAssert( tidyErrorCount( tdoc ) == 0, "Expected tidyErrorCount() == 0" )

        XCTAssert( tidyWarningCount( tdoc ) == 3, "Expected tidyWarningCount() == 3" )

        XCTAssert( tidyAccessWarningCount( tdoc ) == 4, "Expected tidyAccessWarningCount() == 4" )

        XCTAssert( tidyConfigErrorCount( tdoc ) == 1, "Expected tidyConfigErrorCount() == 1" )

        tidyRelease( tdoc )
    }


    /*************************************************************************
      After parsing, Tidy makes available an error summary as well as some
      static general information. In a console application these are normally
      dumped to STDOUT, but as we're not building console applications, we
      want to capture them in a buffer.

      - tidySetErrorBuffer()
      - tidyErrorSummary()
      - tidyGeneralInfo()
      - tidyLocalizedString()
     *************************************************************************/
    func test_errorBufferAndSummaries() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Output goes to STDOUT for this, i.e., we're not keeping it. */
        let _ = tidyParseString( tdoc, "<img src='#'>")

        /* Now let's setup error buffers. */
        let errorBuffer = TidyBuffer()
        let err = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )
        XCTAssert( err == 0, "tidySetErrorBuffer() returned \(err) instead of 0.")

        /* Output goes to our error buffer for these. */
        tidyErrorSummary( tdoc )
        tidyGeneralInfo( tdoc )

        /*
         Our test HTML generates this footnote as part of tidyErrorSummary(),
         and tidyGeneralInfo() finishes with the specified text and newline.
         */
        let messg_expects = tidyLocalizedString( TEXT_M_IMAGE_ALT )
        let messg_ends = "/README/LOCALIZE.md\n"

        if let output = errorBuffer.StringValue() {
            XCTAssert( output.hasPrefix(messg_expects), "The buffer did not start with the expected message." )
            XCTAssert( output.hasSuffix(messg_ends), "The buffer did not end with the expected message." )
        } else {
            XCTFail( "The output buffer was empty!" )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      Tidy offers a cross-platform file exists function, which is good if
      you're writing cross-platform applications. Let's try it out.

      - tidyFileExists()
     *************************************************************************/
    func test_tidyFileExists() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        if var file = testConfig {

            XCTAssert( tidyFileExists( tdoc, file ), "File \(file) does not exist." )

            file += ".xfghjkh"

            XCTAssert( !tidyFileExists( tdoc, file ), "By some strange fluke, file \(file) exists!" )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      Tidy can work with multiple combinations of input and out character
      encodings. We're not going to test that Tidy actually works, because
      we're better off using native encoding methods, and using Tidy in pure
      UTF-8. However, we will test that Tidy accepts our wrapped methods.

      - tidySetCharEncoding()
      - tidySetInCharEncoding()
      - tidySetOutCharEncoding()
      - tidyOptGetInt()
     *************************************************************************/
    func test_tidySetCharEncoding() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Our default input and output encodings should both be 4: UTF8 */
        var inputVal = tidyOptGetInt( tdoc, TidyInCharEncoding )
        var outputVal = tidyOptGetInt( tdoc, TidyOutCharEncoding )
        XCTAssert( inputVal == 4 && outputVal == 4, "The in and out character encoding defaults seem to be wrong.")

        /* tidySetCharEncoding() affects both input and output encodings. */
        let _ = tidySetCharEncoding( tdoc, "mac")
        inputVal = tidyOptGetInt( tdoc, TidyInCharEncoding )   // should be 6
        outputVal = tidyOptGetInt( tdoc, TidyOutCharEncoding ) // should be 1
        XCTAssert( inputVal == 6 && outputVal == 1, "The in and out character encoding settings seem to be wrong.")

        /* Only affect input encoding. */
        let _ = tidySetInCharEncoding( tdoc, "big5")
        inputVal = tidyOptGetInt( tdoc, TidyInCharEncoding )   // should be 12
        outputVal = tidyOptGetInt( tdoc, TidyOutCharEncoding ) // should be 1
        XCTAssert( inputVal == 12 && outputVal == 1, "The in and out character encoding settings seem to be wrong.")

        /* Only affect output encoding. */
        let _ = tidySetOutCharEncoding( tdoc, "win1252")
        inputVal = tidyOptGetInt( tdoc, TidyInCharEncoding )   // should be 12
        outputVal = tidyOptGetInt( tdoc, TidyOutCharEncoding ) // should be 7
        XCTAssert( inputVal == 12 && outputVal == 7, "The in and out character encoding settings seem to be wrong.")

        tidyRelease( tdoc )
    }


    /*************************************************************************
      When Tidy parses a configuration option that it doesn't understand or
      is deprecated, it can call back to a closure or top-level function that
      you provide. SwLibTidy also collects this information for you so that
      you don't have to use callbacks.

      - tidySetConfigCallback()
      - tidyConfigRecords()
     *************************************************************************/
    func test_tidyConfigCallback() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Setup the asynchronous test expectation. */
        let callbackSuccess = XCTestExpectation(description: "The option callback should execute at least once.")

        /* Closures can be used as callbacks, which is what we do here. */
        let _ = tidySetConfigCallback( tdoc, { (tdoc: TidyDoc, option: String, value: String) -> Swift.Bool in

            callbackSuccess.fulfill()

            /*
             Return false to indicate that the callback did NOT handle the
             option, so that Tidy can issue a warning.
             */
            return false
        })

        /* The config contains `mynewconfig`, which is not a valid option. */
        if let file = testConfig {
            let _ = tidyLoadConfig( tdoc, file )
        }

        /* Issue the assert here if the callback doesn't fire at least once. */
        wait(for: [callbackSuccess], timeout: 1.0)

        /*
         Our sample config should have generated at least one record. Using
         tidyConfigRecords() is an SwLibTidy alternative to using a callback.
         The first unknown configuration record in our sample file should be
         for a proposed option 'mynewconfig'.
         */
        if let firstOption = tidyConfigRecords(forTidyDoc: tdoc ).first?.option {
            XCTAssert( firstOption == "mynewconfig", "The first bad option is supposed to be 'mynewconfig'." )
        } else {
            XCTFail( "No configuration records exist." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      Tidy uses the TidyOptionId where it's possible, and instances of
      TidyOption where contextual information is needed.

      This test deals primarily with discovery of options and getting
      instances of options, as well as querying options for information
      about options.

      - tidyGetOptionList()
      - tidyOptGetId()
      - tidyOptGetIdForName()
      - tidyGetOption()
      - tidyGetOptionByName()
      - tidyOptGetName()
      - tidyOptGetType()
      - tidyOptGetCategory()
      - tidyOptionIsList()
     *************************************************************************/
    func test_tidyOptions_general() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        let optionList = tidyGetOptionList( tdoc )
        var result: Bool

        /* Verify that our options list has some options. */
        result = optionList.count > 0
        XCTAssert( result, "The options list is empty." )

        /*
         Verify that the TidyOptionID for the first item is as expected.
         This test is fragile if LibTidy changes its enum ahead of this item.
         */
        if let optionId = tidyOptGetId( optionList[0] ) {
            result = optionId == TidyAccessibilityCheckLevel
            XCTAssert( result, "The TidyOptionId is not as expected." )

        } else {
            XCTFail( "The call to tidyOptGetId() was not successful." )
        }

        /* Verify that getting the option id by name works. */
        result = tidyOptGetIdForName( "fix-backslash") == TidyFixBackslash
        XCTAssert( result, "tidyOptGetIdForName() didn't return a proper result." )

        /*
         Let's get an instance of an option, and try to get its name,
         type, list status, and category.
         */
        if let opt = tidyGetOption( tdoc, TidyIndentSpaces ) {

            /* Verify we have the right option by checking its name. */
            result = tidyOptGetName( opt ) == "indent-spaces"
            XCTAssert( result, "tidyOptGetName() returned an unexpected result." )

            /* This option uses an integer value. */
            result = tidyOptGetType( opt ) == TidyInteger
            XCTAssert( result, "tidyOptGetType() returned an unexpected result." )

            /* This option is from the pretty printing category. */
            result = tidyOptGetCategory( opt ) == TidyPrettyPrint
            XCTAssert( result, "tidyOptGetCategory() returned an unexpected result." )

            /* This option does not take a list. */
            result = tidyOptionIsList( opt )
            XCTAssertFalse( result, "tidyOptionIsList() returned an unexpected result." )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test deals with using options' pick lists, which can be an
      introspective source of information, particularly for GUI programs.

      - tidyOptGetPickList()
      - tidyOptGetCurrPick()
      - tidyOptGetName()
     *************************************************************************/
    func test_tidyOptions_picklists() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* The TidyDoctype option has an interesting list. */
        if let opt = tidyGetOption( tdoc, TidyDoctype ) {

            /* Veryify we have the right option by checking its name. */
            var result = tidyOptGetName( opt ) == "doctype"
            XCTAssert( result, "tidyOptGetName() returned an unexpected result." )

            /* The 5th item should be "transitional". */
            result = tidyOptGetPickList( opt )[4] == "transitional"
            XCTAssert( result, "tidyOptGetPickList() returned an unexpected result." )

            /* The current value should be "auto". */
            result = tidyOptGetCurrPick( tdoc, TidyDoctype) == "auto"
            XCTAssert( result, "The current pick should have been 'auto', but was \(result) instead.")

        } else {
            XCTFail( "tidyGetOption() failed." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test deals with all of the ways to get and set options.

      - tidyGetOption()
      - tidyOptGetDefault()
      - tidyOptGetDefaultInt()
      - tidyOptGetDefaultBool()
      - tidyOptGetValue()
      - tidyOptSetValue()
      - tidyOptParseValue()
      - tidyOptGetInt()
      - tidyOptSetInt()
      - tidyOptGetBool()
      - tidyOptSetBool()
      - tidyOptResetToDefault()
      - tidyOptResetAllToDefault()
      - tidyOptGetEncName()
      - tidyOptGetDeclTagList()
     *************************************************************************/
    func test_tidyOptions_values() {
        
        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        var result: Bool

        /* Let's work with an option of type TidyString. */
        if let opt = tidyGetOption( tdoc, TidyBlockTags ) {

            result = tidyOptGetDefault( opt ) == nil
            XCTAssert( result, "The default for TidyBlockTags should have been nil." )

            result = tidyOptGetValue( tdoc, TidyBlockTags ) == nil
            XCTAssert( result, "The value for TidyBlockTags should have been nil." )

            /* Note how once set, Tidy comma-formats the list. */
            let _ = tidyOptSetValue( tdoc, TidyBlockTags, "one two three" )
            if let result = tidyOptGetValue( tdoc, TidyBlockTags ) {
                XCTAssert( result == "one, two, three", "The option value is not as expected." )
            }

            result = tidyOptGetDeclTagList( tdoc, forOptionId: TidyBlockTags )[1] == "two"
            XCTAssert( result, "The second declared tag should have been 'two'." )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }


        /* Now let's work with a Bool option. */
        if let opt = tidyGetOption( tdoc, TidyFixBackslash ) {

            result = tidyOptGetDefaultBool( opt ) == true
            XCTAssert( result, "The default for TidyFixBackslash should have been true." )

            result = tidyOptGetBool( tdoc, TidyFixBackslash ) == true
            XCTAssert( result, "The value for TidyFixBackslash should have been true." )

            let _ = tidyOptSetBool( tdoc, TidyFixBackslash, false )
            result = tidyOptGetBool( tdoc, TidyFixBackslash ) == false
            XCTAssert( result, "The option value should have been changed to false." )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }


        /* …and an Integer option. */
        if let opt = tidyGetOption( tdoc, TidySortAttributes ) {

            /*
             Note! We return an integer, so if we want to use Tidy's
             enum values, we need to look at its integer value!
             */
            result = tidyOptGetDefaultInt( opt ) == TidySortAttrNone.rawValue
            XCTAssert( result, "The default for TidySortAttributes should have been TidySortAttrNone." )

            /*
             Note! We return an integer, so if we want to use Tidy's
             enum values, we need to look at its integer value!
             */
            result = tidyOptGetInt( tdoc, TidySortAttributes ) == TidySortAttrNone.rawValue
            XCTAssert( result, "The value for TidySortAttributes should have been TidySortAttrNone." )

            /*
             Note! We return an integer, so if we want to use Tidy's
             enum values, we need to look at its integer value!
             */
            let _ = tidyOptSetInt( tdoc, TidySortAttributes, TidySortAttrAlpha.rawValue )
            result = tidyOptGetInt( tdoc, TidySortAttributes ) == TidySortAttrAlpha.rawValue
            XCTAssert( result, "The value for TidySortAttributes should have been TidySortAttrAlpha." )

            /* Can we set this as a string value? It's a pick list. */
            let _ = tidyOptSetValue( tdoc, TidySortAttributes, "none" )
            result = tidyOptGetInt( tdoc, TidySortAttributes ) == TidySortAttrNone.rawValue
            XCTAssert( result, "The value for TidySortAttributes should have been TidySortAttrNone." )

            /* Can we set this as a string value? It's a pick list. */
            result = tidyOptSetValue( tdoc, TidySortAttributes, "invalid" ) == false
            XCTAssert( result, "The value for TidySortAttributes should not have been set." )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }


        /* Let's try to parse a value into a named option. */
        if tidyOptParseValue( tdoc, "show-info", "no" ) {
            result = tidyOptGetBool( tdoc, TidyShowInfo ) == false
            XCTAssert( result, "The value for TidyShowInfo should have been false." )
        } else {
            XCTFail( "tidyOptParseValue() failed." )
        }


        /* Ensure that we can reset an option to default. */
        let _ = tidyOptResetToDefault( tdoc, TidyBlockTags )

        result = tidyOptGetValue( tdoc, TidyBlockTags ) == nil
        XCTAssert( result, "The value for TidyBlockTags should have been nil." )

        /* Ensure that we can reset all options to default. */
        let _ = tidyOptResetAllToDefault( tdoc )

        result = tidyOptGetBool( tdoc, TidyFixBackslash ) == true
        XCTAssert( result, "The value for TidyFixBackslash should have been true." )

        result = tidyOptGetInt( tdoc, TidySortAttributes ) == TidySortAttrNone.rawValue
        XCTAssert( result, "The value for TidySortAttributes should have been TidySortAttrNone." )

        result = tidyOptGetBool( tdoc, TidyShowInfo ) == true
        XCTAssert( result, "The value for TidyShowInfo should have been true." )

        /* Let's get the encoding name for one of the options. */
        result = tidyOptGetEncName( tdoc, TidyInCharEncoding ) == "utf8"
        XCTAssert( result, "The encoding name for TidyInCharEncoding should have been 'utf8'." )

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test is about option snapshots, and copying options between
      document instances.

      - tidyOptSnapshot()
      - tidyOptResetToSnapshot()
      - tidyOptDiffThanDefault()
      - tidyOptDiffThanSnapshot()
      - tidyOptCopyConfig()
     *************************************************************************/
    func test_tidyOptions_snapshots() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        var result: Bool

        result = tidyOptDiffThanDefault( tdoc )
        XCTAssertFalse( result, "The option values should all be default, but aren't." )

        result = tidyOptSnapshot( tdoc )
        XCTAssertTrue( result, "The snapshot should have been taken." )

        if let file = testConfig {
            let _ = tidyLoadConfig( tdoc, file )
        } else {
            XCTFail( "Couldn't load the configuration file." )
        }

        result = tidyOptDiffThanDefault( tdoc )
        XCTAssertTrue( result, "The option values should be different than default, but aren't.")

        let _ = tidyOptSnapshot( tdoc )
        XCTAssert( tidySample( doc: tdoc, useConfig: true ), "tidySample() failed for some reason." )
        result = tidyOptDiffThanSnapshot( tdoc )
        XCTAssertFalse( result, "The option values should be the same as the snapshot, but aren't.")

        let _ = tidyOptResetAllToDefault( tdoc )
        result = tidyOptDiffThanDefault( tdoc )
        XCTAssertFalse( result, "The option values should be same as default, but are different.")

        result = tidyOptDiffThanSnapshot( tdoc )
        XCTAssertTrue( result, "The option values should be different from snapshot, but are the same.")

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test demonstrates that when we set an option, we can read it back.

      - tidyParseString()
      - tidyCleanAndRepair()
      - tidySaveBuffer()
      - tidyOptSetValue()
      - tidyOptSetBool()
      - tidyOptSetInt()
      - tidyOptGetValue()
      - tidyOptGetBool()
      - tidyOptGetInt()
     *************************************************************************/
    func test_tidyOptions_set_get() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        var results: [String] = []

        /*
         Create an array of option id's in a random order, which should
         help us trap any conditions where setting an option value has
         an effect on other option values.
         */
        let options: [TidyOptionId] = tidyGetOptionList( tdoc )
            .flatMap { tidyOptGetId($0) }
            .shuffled()

        /*
         For each tidy option that exists…
         We will check each option immediately after setting it.
         */
        for optId in options {

            guard
                let opt = tidyGetOption( tdoc, optId )
            else { XCTFail( "Could not get option for optId \(optId)." ); return }

            let optType = tidyOptGetType( opt );
            var valueIn = ""
            var valueOut = ""

            /* Skip the stupid TidyInternalCategory options. */
            if tidyOptGetCategory( opt ) == TidyInternalCategory {
                results.append("")
                continue
            }

            /* Make up a value for it and set it. */
            switch optType {

                case TidyString:

                    switch optId {

                        case TidyDoctype: valueIn = random_doctype()

                        case TidyMuteReports: valueIn = random_mute( 4 ).joined(separator: ", ");

                        default: valueIn = random_words( 1 )?.joined(separator: " ") ?? "RandomWordsFailed"
                    }

                    _ = tidyOptSetValue( tdoc, optId, valueIn )


                case TidyInteger:

                    let picklist = tidyOptGetPickList( opt )

                    if picklist.count > 0 {
                        valueIn = String( arc4random_uniform( UInt32(picklist.count - 1) ) )
                    } else {
                        valueIn = String( arc4random_uniform( 100 ))
                    }

                    _ = tidyOptSetInt( tdoc, optId, UInt32(valueIn)! )


                case TidyBoolean:

                    valueIn = arc4random_uniform(2) == 0 ? String(true) : String(false)

                    _ = tidyOptSetBool( tdoc, optId, Bool(valueIn)! )

                default:
                    break
            }


            /* Special case: TidyCSSPrefix: */
            if optId == TidyCSSPrefix {
                valueIn = valueIn + "-"
            }


            /* Remember it. */
            results.append( valueIn )


            /* Read it back in. */
            switch optType {

                case TidyString:  valueOut = tidyOptGetValue( tdoc, optId )!;

                case TidyInteger: valueOut = String( tidyOptGetInt( tdoc, optId ) )

                case TidyBoolean: valueOut = String( tidyOptGetBool( tdoc, optId ) )

                default:
                    break
            }

            /* Compare in and out. */
            let outp = "Option = \(tidyOptGetName( opt )), In = \(valueIn), Out = \(valueOut)."
            XCTAssert( valueIn == valueOut, outp )
        }


        /*
         The test above checked options as they were set. Now let's
         check them all to determine if there's any interaction going on.
         */
        for ( index, optId ) in options.enumerated() {

            guard
                let opt = tidyGetOption( tdoc, optId )
            else { XCTFail( "Could not get option for optId \(optId)." ); return }

            let optType = tidyOptGetType( opt );
            let valueIn = results[index]
            let valueOut: String

            /* Skip the stupid TidyInternalCategory options. */
            if tidyOptGetCategory( opt ) == TidyInternalCategory {
                continue
            }

            /* Read it. */
            switch optType {

            case TidyString:  valueOut = tidyOptGetValue( tdoc, optId )!;

            case TidyInteger: valueOut = String( tidyOptGetInt( tdoc, optId ) )

            case TidyBoolean: valueOut = String( tidyOptGetBool( tdoc, optId ) )

            default:          valueOut = ""
            }

            /* Compare in and out. */
            let outp = "Option = \(tidyOptGetName( opt )), In = \(valueIn), Out = \(valueOut)."
            XCTAssert( valueIn == valueOut, outp )
        }

        /*
            During the main Tidying operations, CLibTidy changes the
            configuration for internal use, but does _not_ restore it until
            the buffer is saved (although you can manually restore it). This
            bit below goes through a typical Tidy cycle, and saves the buffer,
            which should ensure that our options are exactly how we set them.
         */
        let outpBuffer = TidyBuffer()
        _ = tidyParseString( tdoc, "<h1>How now, brown cow?</h1>")
        _ = tidyCleanAndRepair( tdoc )
        _ = tidySaveBuffer( tdoc, outpBuffer ) /* needed to restore snapshot */


        /*
         Now ensure that the act of Tidying a document doesn't fiddle with
         the configuration settings.
         */
        for ( index, optId ) in options.enumerated() {

            guard
                let opt = tidyGetOption( tdoc, optId )
            else { XCTFail( "Could not get option for optId \(optId)." ); return }

            let optType = tidyOptGetType( opt );
            let valueIn = results[index]
            let valueOut: String

            /* Skip the stupid TidyInternalCategory options. */
            if tidyOptGetCategory( opt ) == TidyInternalCategory {
                continue
            }

            /* Read it. */
            switch optType {

            case TidyString:  valueOut = tidyOptGetValue( tdoc, optId )!;

            case TidyInteger: valueOut = String( tidyOptGetInt( tdoc, optId ) )

            case TidyBoolean: valueOut = String( tidyOptGetBool( tdoc, optId ) )

            default:          valueOut = ""
            }

            /* Compare in and out. */
            let outp = "Option = \(tidyOptGetName( opt )), In = \(valueIn), Out = \(valueOut)."
            XCTAssert( valueIn == valueOut, outp )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
     A whole lot of Tidy is dedicated to managing options, and clients will
     want to manage options as well.

     This test demonstrates that all of the string options can take empty
     strings without failing. This does not imply that the setting is valid,
     for example, TidyDocType will always have a doctype.

     - tidyOptSetValue()
     *************************************************************************/
    func test_tidyOptions_emptystrings() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Get all of the option Id's of type TidyString */
        let stringOptions: [TidyOptionId] = tidyGetOptionList( tdoc )
            .flatMap { tidyOptGetType( $0 ) == TidyString ? $0 : nil }
            .flatMap { tidyOptGetId( $0 ) }

        for optId in stringOptions {

            /* Ensure we can set null strings. */
            let result = tidyOptSetValue( tdoc , optId, "")
            XCTAssert( result, "Option \(optId) did not accept a null string!")
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
     A whole lot of Tidy is dedicated to managing options, and clients will
     want to manage options as well.

     This test demonstrates the iterators for prioritized attributes and for
     muted messages.

     - tidyOptGetPriorityAttrList()
     - tidyOptGetMutedMessageList()
     - tidyOptGetDeclTagList()
     *************************************************************************/
    func test_tidyOptions_iterators() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        XCTAssert( tidyOptGetMutedMessageList( tdoc ).count == 0, "Expected the array to be empty." )
        XCTAssert( tidyOptGetPriorityAttrList( tdoc ).count == 0, "Expected the array to be empty." )
        XCTAssert( tidyOptGetDeclTagList( tdoc, forOptionId: TidyBlockTags ).count == 0, "Expected the array to be empty." )

        let muteArray = random_mute( 5 )
        let muteVal = muteArray.joined(separator: ", ")
        let attrArray = [ "id", "name", "class" ]
        let attrVal = attrArray.joined(separator: ", ")

        _ = tidyOptSetValue( tdoc, TidyMuteReports, muteVal )
        _ = tidyOptSetValue( tdoc, TidyPriorityAttributes, attrVal )

        XCTAssert( tidyOptGetMutedMessageList( tdoc )[2] == muteArray[2], "The array did not return the value expected." )
        XCTAssert( tidyOptGetPriorityAttrList( tdoc )[2] == attrArray[2], "The array did not return the value expected." )

        if let tagsArray = random_words( 7 ) {
            let tagsVal = tagsArray.joined(separator: ", ")
            _ = tidyOptSetValue( tdoc, TidyBlockTags, tagsVal )
            let listArray = tidyOptGetDeclTagList( tdoc, forOptionId: TidyBlockTags )
            XCTAssert( listArray[2] == tagsArray[2], "The array did not return the value expected." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test demonstrates how an fpi can be set in the doctype option.

      - tidyOptGetDoc()
      - tidyOptGetDocLinksList()
     *************************************************************************/
    func test_tidyOptions_doctype_fpi() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* The TidyDoctype option has an interesting list. */
        if let opt = tidyGetOption( tdoc, TidyDoctype ) {

            /* Veryify we have the right option by checking its name. */
            var result = tidyOptGetName( opt ) == "doctype"
            XCTAssert( result, "tidyOptGetName() returned an unexpected result." )

            /* Set an FPI */
            let fpi = "-//HELLO/WORLD"
            let qfpi = "\"\(fpi)\""

            /* Ensure we can set it with an unquoted string, such as from
               a console. */
            result = tidyOptSetValue( tdoc, TidyDoctype, fpi )
            XCTAssert( result, "tidyOptSetValue() returned an unexpected result." )

            var new_fpi = tidyOptGetValue( tdoc, TidyDoctype )
            result = new_fpi == fpi
            XCTAssert( result, "tidyOptGetValue() returned an unexpected result." )

            /* Ensure we can set it with a quoted string, since the API used to
               demand this. */
            result = tidyOptSetValue( tdoc, TidyDoctype, qfpi )
            XCTAssert( result, "tidyOptSetValue() returned an unexpected result." )

            new_fpi = tidyOptGetValue( tdoc, TidyDoctype )
            result = new_fpi == fpi
            XCTAssert( result, "tidyOptGetValue() returned an unexpected result." )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test demonstrates how documentation for Tidy options can be
      generated, and it is fragile if CLibTidy changes its documentation.

      - tidyOptGetDoc()
      - tidyOptGetDocLinksList()
     *************************************************************************/
    func test_tidyOptions_documentation() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Let's get the documentation for TidyPreTags, since it has xref
           links we can look at, too. */
        if let topt = tidyGetOption( tdoc, TidyPreTags ) {

            let dox = tidyOptGetDoc( tdoc, topt )
            let prefix = "This option specifies new tags that are to be processed in exactly the"
            XCTAssert( dox.hasPrefix( prefix ), "The expected documentation was not received." )

            let xref: [TidyOption] = tidyOptGetDocLinksList( tdoc, topt )

            /* There are five items in the list. If you're looking at the
               CLibTidy source code, TidyUnknownOption is a list end marker,
               and not part of the cross reference. */
            XCTAssert( xref.count == 4, "Expected to see 4 items, but saw \(xref.count)." )

            /* And the third one should be TidyInlineTags. */
            XCTAssert( tidyOptGetId(xref[2]) == TidyInlineTags, "Expected TidyInlineTags, but got something else." )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      When Tidy is used with the gnu-emacs option, it will display its error
      reports in a format that's useful to emacs users. The implementing
      program will have to specify the file and path to be used in this
      modified report.

      - tidySetEmacsFile()
      - tidyGetEmacsFile()
     *************************************************************************/
    func test_tidyOptions_emacs() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        let emacs_file = "/home/charliebrown/httpd/mywebsite"

        /* Setup error buffers. */
        let errorBuffer = TidyBuffer()
        let err = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )
        XCTAssert( err == 0, "tidySetErrorBuffer() returned \(err) instead of 0.")

        /* Tidy the sample file with gnu-emacs set to true, and a path
           specified. */
        let _ = tidyOptSetBool( tdoc, TidyEmacs, true )
        tidySetEmacsFile( tdoc, emacs_file )
        let _ = tidySample( doc: tdoc, useConfig: false )

        /* Let's make sure tidyGetEmacsFile() still gives us the same. */
        XCTAssert( tidyGetEmacsFile( tdoc) == emacs_file, "tidyGetEmacsFile() returned incorrect value." )

        /* Finally, let's see if the error table is prefixed with the correct
           emacs file information. */
        if let output = errorBuffer.StringValue() {
            let prefix_expected = "\(emacs_file):1:1:"
            XCTAssert( output.hasPrefix(prefix_expected), "Expected the prefix to be \(prefix_expected)." )
        } else {
            XCTFail( "The error buffer had no contents!" )
        }

        tidyRelease( tdoc )
    }


    /*************************************************************************
      When Tidy makes a change to a configuration option, it can callback
      into your application.

      - tidySetConfigChangeCallback()
     *************************************************************************/
    func test_tidyOptions_changeCallback() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Setup expectation for asynchronous test. In this case, we
           set an option various times below, and so the final count
           should match our expectation. */
        let callbackSuccess = XCTestExpectation(description: "The option change callback should execute 5 times.")
        callbackSuccess.expectedFulfillmentCount = 5

        /* Callbacks can be Swift closures, so this test takes advantage of
           that. You're free to use a top-level function that uses the
           correct typealias for any callback, too, but this keeps the
           test suite orderly.
         */
        let _ = tidySetConfigChangeCallback( tdoc, { tdoc, option in

            if let id = tidyOptGetId( option )
            {
                /* We won't really test for anything here, but we can look
                   at some interesting console output if we want to.
                 */
                let name = tidyOptGetName( option )

                switch tidyOptGetType( option ) {

                case TidyString:
                    let newval = tidyOptGetValue( tdoc, id ) ?? "NULL"
                    print("Option \(name) changed. New value is \(newval)")

                case TidyBoolean:
                    let newval = tidyOptGetBool( tdoc, id )
                    print("Option \(name) changed. New value is \(newval)")

                case TidyInteger:
                    let newval = tidyOptGetInt( tdoc, id )
                    print("Option \(name) changed. New value is \(newval)")

                default:
                    let newval = tidyOptGetInt( tdoc, id )
                    print("Option \(name) changed. New value is \(newval)")
                }
            }

            /* Adds +1 to the expectedFulfillmentCount. */
            callbackSuccess.fulfill()
        })

        /* +1 Callback should be called, because the default was empty. */
        _ = tidyOptSetValue( tdoc, TidyBlockTags, "jack, jim, joe" )

        /* +0 Callback should *not* be called, because the same value was
           given, meaning that no change actually occurred! */
        _ = tidyOptSetValue( tdoc, TidyBlockTags, "jack, jim, joe" )

        /* +1 Callback should be called because we are resetting to default. */
        _ = tidyOptResetAllToDefault( tdoc )

        /* +1 Callback should be called. */
        _ = tidyOptSetInt( tdoc, TidyWrapLen, 80 )

        /* +2 Callback should be called twice, because `ident-with-tabs`
           also changes `indent-spaces`. */
        _ = tidyOptParseValue( tdoc, "indent-with-tabs", "yes" )

        /* +0 Callbacks should not occur when internal changes occur. */
        _ = tidyParseString( tdoc, "<p>How now, Mr. Cow?" )
        _ = tidyCleanAndRepair( tdoc )

        /* Issue the assert here if the callback doesn't fire at least once. */
        wait(for: [callbackSuccess], timeout: 1.0)

        tidyRelease( tdoc )
    }


    /*************************************************************************
      Tidy normally sends message output to STDOUT, which can be useful in
      command line tools, but luckily Tidy supports other types of output,
      as demonstrated in this test.

      - tidySetErrorFile()
      - tidySetErrorBuffer()
     *************************************************************************/
    func test_errorOut() {

    }


    /*************************************************************************
      Sophisticated programs will want more control over Tidy's message
      output, and the use of the message callback enables this. This test
      demonstrates setting up such a callback.

      - tidySetMessageCallback()
     *************************************************************************/
    func test_messageCallback() {

    }


    /*************************************************************************
      Tidy's message callback provides instances of TidyMessage, which is an
      opaque type that uses an API to interrogate, as demonstrated in this
      test.

      - tidySetMessageCallback()
      - tidyGetMessageDoc()
      - tidyGetMessageCode()
      - tidyGetMessageKey()
      - tidyGetMessageLine()
      - tidyGetMessageColumn()
      - tidyGetMessageLevel()
      - tidyGetMessageFormatDefault()
      - tidyGetMessageFormat()
      - tidyGetMessageDefault()
      - tidyGetMessage()
      - tidyGetMessagePosDefault()
      - tidyGetMessagePos()
      - tidyGetMessagePrefixDefault()
      - tidyGetMessagePrefix()
      - tidyGetMessageOutputDefault()
      - tidyGetMessageOutput()
     *************************************************************************/
    func test_tidyMessage() {

    }


    /*************************************************************************
      Tidy's message callback provides instances of TidyMessage, which is an
      opaque type that uses an API to interrogate. This message interrogation
      API includes tidyGetMessageArguments() to return an array of
      TidyMessageArgument, which has its own access API for discovering the
      components of a message's original format string.

      - tidyGetMessageArguments()
      - tidyGetArgType()
      - tidyGetArgFormat()
      - tidyGetArgValueString()
      - tidyGetArgValueUInt()
      - tidyGetArgValueInt()
      - tidyGetArgValueDouble()
     *************************************************************************/
    func test_tidyMessageArguments() {

    }


    /*************************************************************************
      SwLibTidy adds a feature to Tidy that can avoid all of the message
      callback and nested APIs. The tidyMessageRecords() function provides
      an instance of a class or structure that captures all of the message
      related information into a nice, easy to use structure.

      - tidyMessageRecords()
     *************************************************************************/
    func test_tidyMessageRecords() {

    }


    /*************************************************************************
      Tidy provides a simple pretty pretter callback and a convenience
      function (for avoiding a callback) that can be used to track the
      progress of the pretty printing process. It correlates (as best as is
      possible) where location of source document components in the tidied
      document. This might be useful, for example, in scrolling before and
      after documents in a synchronized fashion.

      - tidySetPrettyPrinterCallback()
      - tidyPrettyPrinterRecords()
     *************************************************************************/
    func test_ppCallback() {

    }


    /*************************************************************************
      A parsed document can have additional clean and repair operations
      performed upon it, as well as report some related information about
      the process.

      - tidyCleanAndRepair()
      - tidyRunDiagnostics()
      - tidyReportDocType()
     *************************************************************************/
    func test_diagnostics() {

    }


    /*************************************************************************
      Saving tidied files to different output types is directly supported by
      Tidy, although it's probably more likely you will take advantage of
      macOS-native means. Still, you need to learn how to save to a buffer,
      here.

      - tidySaveFile()
      - tidySaveStdout()
      - tidySaveBuffer()
     *************************************************************************/
    func test_tidySave() {

    }


    /*************************************************************************
      Tidy supports saving configuration files directly, however it only
      writes from a given document's configuration, and only for options that
      have non-default values (it's trivial to do this yourself anyway).

      - tidyOptSaveFile()
     *************************************************************************/
    func test_tidyOptSave() {

    }


    /*************************************************************************
      Although Tidy is well known as an error-correcting parser and pretty
      printer, it's also very capable of being used to work with HTML nodes
      directly. This test demonstrates how to get the major nodes of a
      parsed document, as well as how to traverse the document.

      - tidyGetRoot()
      - tidyGetHtml()
      - tidyGetHead()
      - tidyGetBody()
      - tidyGetParent()
      - tidyGetChild()
      - tidyGetNext()
      - tidyGetPrev()
      - tidyDiscardElement()
     *************************************************************************/
    func test_traversal() {

    }


    /*************************************************************************
      Given a node, Tidy makes it simple to work with the node's attributes.
      This test demonstrates this important feature.

      - tidyAttrFirst()
      - tidyAttrNext()
      - tidyAttrName()
      - tidyAttrValue()
      - tidyAttrDiscard()
      - tidyAttrGetId()
      - tidyAttrIsEvent()
      - tidyAttrGetById()
     *************************************************************************/
    func test_attributes() {

    }


    /*************************************************************************
      Given a node, Tidy makes it simple to work with other information about
      the node, as tested in this case.

      - tidyNodeGetType()
      - tidyNodeGetName()
      - tidyNodeIsText()
      - tidyNodeIsProp()
      - tidyNodeIsHeader()
      - tidyNodeHasText()
      - tidyNodeGetText()
      - tidyNodeGetValue()
      - tidyNodeGetId()
      - tidyNodeLine()
      - tidyNodeColumn()
     *************************************************************************/
    func test_node_interrogation() {

    }


    /*************************************************************************
      Tidy works with message codes internally as enums, and these carry over
      fairly well into Swift and excellently in Objective-C, however the
      specific values are *never* guaranteed. This means that we need some
      persistent string-based representation of message codes for use outside
      of LibTidy and outside of linked applications. For example, for string
      lookup in localized versions of .strings files.

      These functions provide discovery of these persistent strings.

      - tidyErrorCodeAsKey()
      - tidyErrorCodeFromKey()
      - getErrorCodeList()
     *************************************************************************/
    func test_error_codes() {

    }


    /*************************************************************************
      Tidy natively supports localization, although your higher-level classes
      may choose to use macOS localization instead. Tidy always gets strings
      of type `tidyStrings`, except when it doesn't, because in addition to
      strings for each `tidyStrings`, it also has strings for `TidyOptionID`
      `TidyConfigCategory` and `TidyReportLevel`. This compromise between
      sloppiness and functionality make it difficult for us to enforce type
      safety in Swift, but there are always workarounds: C enumerations
      imported by Swift do not fail when initializing with a raw value that
      does not correspond to an enumeration case. This is done for
      compatibility with C, which allows any value to be stored in an
      enumeration, including values used internally but not exposed in
      headers.

      - tidyLocalizedString()
      - tidyLocalizedStringN()
      - tidyDefaultString()
      - tidySetLanguage()
     *************************************************************************/
    func test_tidyLocalizedString() {

        var messg_expects: String

        /*
         The singular for the given message. Because the current locale is
         the default locale, we get same result as tidyDefaultString().
         */
        messg_expects = tidyLocalizedString( STRING_ERROR_COUNT_ERROR )
        XCTAssert( messg_expects == "error", "The string 'error' was not returned." )

        /*
         The form of the message if there are five of whatever we're looking
         for. There are only a few plural strings used in Tidy.
         */
        messg_expects = tidyLocalizedStringN( STRING_ERROR_COUNT_ERROR, 5 )
        XCTAssert( messg_expects == "errors", "The string 'errors' was not returned." )

        /* Let's set the language and lookup a French string. */
        let _ = tidySetLanguage("fr")

        messg_expects = tidyLocalizedString( STRING_SPECIFIED )
        XCTAssert( messg_expects == "précisé", "The string 'précisé' was not returned." )

        /*
         Oops! We want a TidyReportLevel as a string! This works for any of
         the other types that have strings defined, too. And if we're in
         French, we should get the English string anyway.
         */
        messg_expects = tidyDefaultString( tidyStrings.init( TidyInfo.rawValue) )
        XCTAssert( messg_expects == "Info: ", "The string 'Info: ' was not returned." )

        /* XCTest runs these asynchronously, so better reset to English. */
        let _ = tidySetLanguage("en")
    }


    /*************************************************************************
      Tidy natively supports localization, although your higher-level classes
      may choose to use macOS localization instead. These extra utilities
      make it simple to support Tidy's native localization support.

      - tidySystemLocale()
      - tidySetLanguage()
      - tidyGetLanguage()
      - getWindowsLanguageList()
      - TidyLangWindowsName()
      - TidyLangPosixName()
      - getInstalledLanguageList()
      - getStringKeyList()
     *************************************************************************/
    func test_locales() {

    }

}
