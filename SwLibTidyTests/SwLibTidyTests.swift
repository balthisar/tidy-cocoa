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
        defer { tidyRelease( tdoc ) }

        tidySetAppData( tdoc, self )
        let gotObject = tidyGetAppData( tdoc )
    
        XCTAssert( gotObject === self, "The object stored is not that same as the object retrieved." )
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
        let expectedVers = "5.7"
        let expectedPlat = "Apple"

        JSDAssertHasPrefix( expectedDate, tidyReleaseDate() )
        JSDAssertHasPrefix( expectedVers, tidyLibraryVersion() )
        JSDAssertHasPrefix( expectedPlat, tidyPlatform() )
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
        defer { tidyRelease( tdoc ) }

        if let file = testConfig {

            let _ = tidyLoadConfig( tdoc, file )
            JSDAssertEqual( 3, tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel ) )

            let _ = tidyOptResetAllToDefault( tdoc )
            JSDAssertEqual( 0, tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel ) )

            let _ = tidyLoadConfigEnc( tdoc, file, "ascii")
            JSDAssertEqual( 3, tidyOptGetInt( tdoc, TidyAccessibilityCheckLevel ) )
        }
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
        defer { tidyRelease( tdoc ) }

        let format = "Expected tidyParse…() == %1$@, but it was %2$@."

        /* We'll throw away the return value, so we can test tidyStatus(). */
        let _ = tidyParseString( tdoc, "<h1>Hello, world!</h2>" )
        let result = tidyStatus( tdoc )
        JSDAssertEqual( 1, result, format )

        /* Use the return value directly. */
        if let file = testHtml {
            JSDAssertEqual( 1, tidyParseFile( tdoc, file ), format )
        }

        /* Redirect a file to stdin, so we can test tidyParseStdin(). */
        if let file = testHtml {
            freopen( file, "r", stdin )
            JSDAssertEqual( 1, tidyParseStdin( tdoc ), format )
        }
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
        defer { tidyRelease( tdoc ) }

        XCTAssert( tidySample( doc: tdoc, useConfig: true ), "tidySample() failed for some reason." )

        let format = "Expected tidyFunction() == %1$@, but it was %2$@"

        JSDAssertEqual( 1,     tidyStatus( tdoc),              format )
        JSDAssertEqual( false, tidyDetectedXhtml( tdoc ),      format )
        JSDAssertEqual( false, tidyDetectedGenericXml( tdoc ), format )
        JSDAssertEqual( 0,     tidyErrorCount( tdoc ),         format )
        JSDAssertEqual( 6,     tidyWarningCount( tdoc ),       format )
        JSDAssertEqual( 5,     tidyAccessWarningCount( tdoc ), format )
        JSDAssertEqual( 1,     tidyConfigErrorCount( tdoc ),   format )
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
        defer { tidyRelease( tdoc ) }

        /* Output goes to STDOUT for this, i.e., we're not keeping it. */
        let _ = tidyParseString( tdoc, "<img src='#'>")

        /* Now let's setup error buffers. */
        let errorBuffer = SwTidyBuffer()
        let err = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )
        XCTAssert( err == 0, "tidySetErrorBuffer() returned \(err) instead of 0.")

        /* Output goes to our error buffer for these. */
        tidyErrorSummary( tdoc )
        tidyGeneralInfo( tdoc )

        /*
         Our test HTML generates this footnote as part of tidyErrorSummary(),
         and tidyGeneralInfo() finishes with the specified text and newline.
         */
        let messg_start = tidyLocalizedString( TEXT_M_IMAGE_ALT )
        let messg_end = "/README/LOCALIZE.md\n"

        if let output = errorBuffer.StringValue() {
            JSDAssertHasPrefix( messg_start, output )
            JSDAssertHasSuffix( messg_end, output )
        } else {
            XCTFail( "The output buffer was empty!" )
        }
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
        defer { tidyRelease( tdoc ) }

        if var file = testConfig {

            XCTAssert( tidyFileExists( tdoc, file ), "File \(file) does not exist." )

            file += ".xfghjkh"

            XCTAssert( !tidyFileExists( tdoc, file ), "By some strange fluke, file \(file) exists!" )
        }
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
        defer { tidyRelease( tdoc ) }

        let inp_format = "The input encoding should be %1$@, but was %2$@."
        let out_format = "The output encoding should be %1$@, but was %2$@."

        /* Our default input and output encodings should both be 4: UTF8 */
        JSDAssertEqual( 4, tidyOptGetInt( tdoc, TidyInCharEncoding ), inp_format )
        JSDAssertEqual( 4, tidyOptGetInt( tdoc, TidyOutCharEncoding ), out_format )

        /* tidySetCharEncoding() affects both input and output encodings. */
        let _ = tidySetCharEncoding( tdoc, "mac")
        JSDAssertEqual( 6, tidyOptGetInt( tdoc, TidyInCharEncoding ), inp_format )
        JSDAssertEqual( 1, tidyOptGetInt( tdoc, TidyOutCharEncoding ), out_format )

        /* Only affect input encoding. */
        let _ = tidySetInCharEncoding( tdoc, "big5")
        JSDAssertEqual( 12, tidyOptGetInt( tdoc, TidyInCharEncoding ), inp_format )
        JSDAssertEqual( 1, tidyOptGetInt( tdoc, TidyOutCharEncoding ), out_format )

        /* Only affect output encoding. */
        let _ = tidySetOutCharEncoding( tdoc, "win1252")
        JSDAssertEqual( 12, tidyOptGetInt( tdoc, TidyInCharEncoding ), inp_format )
        JSDAssertEqual( 7, tidyOptGetInt( tdoc, TidyOutCharEncoding ), out_format )

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
        defer { tidyRelease( tdoc ) }

        /* Setup the asynchronous test expectation. */
        let callbackSuccess = XCTestExpectation( description: "The callback should execute at least once." )

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
        let records = tidyConfigRecords( forTidyDoc: tdoc )
        dump( records )

        if let firstOption = records.first?.option {
            JSDAssertEqual( "mynewconfig", firstOption, "The first bad option is supposed to be '%1$@'." )
        } else {
            XCTFail( "No configuration records exist." )
        }
    }


    /*************************************************************************
      When Tidy parses a configuration option that it doesn't understand or
      is deprecated, it can call back to a closure or top-level function that
      you provide. SwLibTidy also collects this information for you so that
      you don't have to use callbacks, and you can use your own, conforming
      class for this data collection.

      - setTidyConfigRecords()
      - tidyConfigRecords()
     *************************************************************************/
    func test_setTidyConfigRecords() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        /* Use a different class to populate the tidyConfigRecords() array. We
           might want to do this if we want a class that's a bit more
           sophisticated than the default class. Our sample class will alter
           the proposed value in a way that we can detect.
         */
        if !setTidyConfigRecords( toClass: AlternateTidyConfigReport.self, forTidyDoc: tdoc ) {
            XCTFail( "setTidyConfigRecords() failed for some reason." )
            return
        }

        /* The config contains `mynewconfig`, which is not a valid option. */
        if let file = testConfig {
            let _ = tidyLoadConfig( tdoc, file )
        }

        /*
         Our sample config should have generated at least one record. Using
         tidyConfigRecords() is an SwLibTidy alternative to using a callback.
         The first unknown configuration record in our sample file should be
         for a proposed option 'mynewconfig'.
         */
        if let result = tidyConfigRecords( forTidyDoc: tdoc ).first?.value {
            let expected = "---poopy---"
            JSDAssertEqual( expected, result )
        } else {
            XCTFail( "No configuration records exist." )
        }
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
        defer { tidyRelease( tdoc ) }

        let optionList = tidyGetOptionList( tdoc )

        /* Verify that our options list has some options. */
        XCTAssert( optionList.count > 0, "The options list is empty." )

        /*
         Verify that the TidyOptionID for the first item is as expected.
         This test is fragile if LibTidy changes its enum ahead of this item.
         */
        if let optionId = tidyOptGetId( optionList[0] ) {
            JSDAssertEqual( TidyAccessibilityCheckLevel, optionId )
        } else {
            XCTFail( "The call to tidyOptGetId() was not successful." )
        }

        /* Verify that getting the option id by name works. */
        JSDAssertEqual( TidyFixBackslash, tidyOptGetIdForName( "fix-backslash") ?? TidyUnknownOption )

        /*
         Let's get an instance of an option, and try to get its name,
         type, list status, and category.
         */
        if let opt = tidyGetOption( tdoc, TidyIndentSpaces ) {

            /* Verify we have the right option by checking its name. */
            JSDAssertEqual( "indent-spaces", tidyOptGetName( opt ) )

            /* This option uses an integer value. */
            JSDAssertEqual( TidyInteger, tidyOptGetType( opt ) )

            /* This option is from the pretty printing category. */
            JSDAssertEqual( TidyPrettyPrint, tidyOptGetCategory( opt ) )

            /* This option does not take a list. */
            JSDAssertEqual( false, tidyOptionIsList( opt ) )

        } else {
            XCTFail( "tidyGetOption() failed." )
        }

        if let _ = tidyGetOptionByName( tdoc, "hello-world" ) {
            XCTFail( "tidyGetOptionByName() returned option for invalid string." )
        }

        if let _ = tidyGetOptionByName( tdoc, "wrap" ){} else {
            XCTFail( "tidyGetOptionByName() did not return a valid option." )
        }
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
        defer { tidyRelease( tdoc ) }

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
        defer { tidyRelease( tdoc ) }

        var result: Bool

        /* Let's work with an option of type TidyString. */
        if let opt = tidyGetOption( tdoc, TidyBlockTags ) {

            result = tidyOptGetDefault( opt ) == ""
            XCTAssert( result, "The default for TidyBlockTags should have been an empty string." )

            result = tidyOptGetValue( tdoc, TidyBlockTags ) == ""
            XCTAssert( result, "The value for TidyBlockTags should have been an empty string." )

            /* Note how once set, Tidy comma-formats the list. */
            let _ = tidyOptSetValue( tdoc, TidyBlockTags, "one two three" )
            result = tidyOptGetValue( tdoc, TidyBlockTags ) == "one, two, three"
            XCTAssert( result, "The option value is not as expected." )

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

        result = tidyOptGetValue( tdoc, TidyBlockTags ) == ""
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
        defer { tidyRelease( tdoc ) }

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
        defer { tidyRelease( tdoc ) }

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

                case TidyString:  valueOut = tidyOptGetValue( tdoc, optId );

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

            case TidyString:  valueOut = tidyOptGetValue( tdoc, optId );

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
        let outpBuffer = SwTidyBuffer()
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

            case TidyString:  valueOut = tidyOptGetValue( tdoc, optId );

            case TidyInteger: valueOut = String( tidyOptGetInt( tdoc, optId ) )

            case TidyBoolean: valueOut = String( tidyOptGetBool( tdoc, optId ) )

            default:          valueOut = ""
            }

            /* Compare in and out. */
            let outp = "Option = \(tidyOptGetName( opt )), In = \(valueIn), Out = \(valueOut)."
            XCTAssert( valueIn == valueOut, outp )
        }
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
        defer { tidyRelease( tdoc ) }

        /* Get all of the option Id's of type TidyString */
        let stringOptions: [TidyOptionId] = tidyGetOptionList( tdoc )
            .flatMap { tidyOptGetType( $0 ) == TidyString ? $0 : nil }
            .flatMap { tidyOptGetId( $0 ) }

        for optId in stringOptions {

            /* Ensure we can set null strings. */
            let result = tidyOptSetValue( tdoc , optId, "")
            XCTAssert( result, "Option \(optId) did not accept a null string!")
        }
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
        defer { tidyRelease( tdoc ) }

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
        defer { tidyRelease( tdoc ) }

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
        defer { tidyRelease( tdoc ) }

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
        defer { tidyRelease( tdoc ) }

        let emacs_file = "/home/charliebrown/httpd/mywebsite"

        /* Setup error buffers. */
        let errorBuffer = SwTidyBuffer()
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
        defer { tidyRelease( tdoc ) }

        /* Setup expectation for asynchronous test. In this case, we
           set an option various times below, and so the final count
           should match our expectation. */
        let callbackSuccess = XCTestExpectation(description: "The callback should execute 5 times.")
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
                    let newval = tidyOptGetValue( tdoc, id )
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
    }


    /*************************************************************************
      Tidy normally sends message output to STDOUT, which can be useful in
      command line tools, but luckily Tidy supports other types of output,
      as demonstrated in this test.

      - tidySetErrorFile()
     *************************************************************************/
    func test_errorOut() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }

        /* Setup error file -- assume we have permissions for tmp file. */
        let errorFile = "\(NSTemporaryDirectory())\(NSUUID().uuidString).txt"
        let errorURL = URL(fileURLWithPath: errorFile)
        guard
            let _ = tidySetErrorFile( tdoc, errorFile )
        else {
            XCTFail( "tidySetErrorFile() unsuccessful for '\(errorFile)'" )
            return
        }

        /* Generate some output - file not written until TidyRelease() */
        let _ = tidySample( doc: tdoc, useConfig: false )
        tidyRelease( tdoc )


        /* Read the beginning of the file to ensure it matches our
           expections. */
        do {
            let expects = "line 1 column 1 - Warning: missing <!DOCTYPE> declaration"
            let result = try String(contentsOf: errorURL, encoding: .utf8)
            print( result )
            XCTAssert( result.hasPrefix( expects ), "The file did not have the content expected." )
        }
        catch {
            XCTFail( "Could not read '\(errorFile)'." )
        }
    }


    /*************************************************************************
      Sophisticated programs will want more control over Tidy's message
      output, and the use of the message callback enables this. This test
      demonstrates setting up such a callback, as well as uses the message
      interrogation API in order to pick apart the message.

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
      - tidyGetMessageArguments()
      - tidyGetArgType()
      - tidyGetArgFormat()
      - tidyGetArgValueString()
      - tidyGetArgValueUInt()
      - tidyGetArgValueInt()
      - tidyGetArgValueDouble()
     *************************************************************************/
    func test_messageCallback() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        /* Setup the asynchronous test expectation. */
        let callbackSuccess = XCTestExpectation(description: "The callback should execute at least once.")


        /* Closures can be used as callbacks, which is what we do here. */
        let _ = tidySetMessageCallback( tdoc, { ( tmessage: TidyMessage ) -> Swift.Bool in

            callbackSuccess.fulfill()

            /* Let's pick this apart: */
            let expect_complete = "line 1 column 18 - Warning: discarding unexpected </h2>"

            /* The message API returns the various pieces that makes up a
               message in Tidy. You can use these to provide your own
               messages, and provide your own localizations. */
            let doc = tidyGetMessageDoc( tmessage )
            let code = tidyGetMessageCode( tmessage )
            let key = tidyGetMessageKey( tmessage )
            let line = tidyGetMessageLine( tmessage )
            let col = tidyGetMessageColumn( tmessage )
            let level = tidyGetMessageLevel( tmessage )
            let formatDef = tidyGetMessageFormatDefault( tmessage )
            let formatLoc = tidyGetMessageFormat( tmessage )
            let mssgDef = tidyGetMessageDefault( tmessage )
            let mssgLoc = tidyGetMessage( tmessage )
            let posDef = tidyGetMessagePosDefault( tmessage )
            let posLoc = tidyGetMessagePos( tmessage )
            let prefixDef = tidyGetMessagePrefixDefault( tmessage )
            let prefixLoc = tidyGetMessagePrefix( tmessage )
            let outDef = tidyGetMessageOutputDefault( tmessage )
            let outLoc = tidyGetMessageOutput( tmessage )

            XCTAssert( doc == tdoc, "The message gave us the wrong TidyDocument." )
            XCTAssert( code == DISCARDING_UNEXPECTED.rawValue, "Received the wrong message code." )
            XCTAssert( key == "DISCARDING_UNEXPECTED", "Received the wrong message code." )
            XCTAssert( line == 1, "Was expecting a different line number." )
            XCTAssert( col ==  18, "Was expecting a different column number." )
            XCTAssert( level == TidyWarning, "Was expecting a different message level." )
            XCTAssert( formatDef == "discarding unexpected %s", "Was expecting a different format string." )
            XCTAssert( formatLoc == "discarding unexpected %s", "Was expecting a different format string." )
            XCTAssert( mssgDef == "discarding unexpected </h2>", "Was expecting a different message." )
            XCTAssert( mssgLoc == "discarding unexpected </h2>", "Was expecting a different message." )
            XCTAssert( posDef == "line 1 column 18 - ", "Was expecting a different message position." )
            XCTAssert( posLoc == "line 1 column 18 - ", "Was expecting a different message position." )
            XCTAssert( prefixDef == "Warning: ", "Was expecting a different message prefix." )
            XCTAssert( prefixLoc == "Warning: ", "Was expecting a different message prefix." )
            XCTAssert( outDef == expect_complete, "Was expecting a different message." )
            XCTAssert( outLoc == expect_complete, "Was expecting a different message." )

            /* Messages are composed of C format strings, which are compatible
               with Swift and reflected in the tidyGetMessageFormat() and
               tidyGetMessageFormatDefault() functions. The arguments to
               fill this format string can be sussed out with the following:
             */
            let arguments = tidyGetMessageArguments(forMessage: tmessage)
            let argType = tidyGetArgType( tmessage, arguments[0] )
            let argFormat = tidyGetArgFormat( tmessage, arguments[0] )

            XCTAssert( arguments.count == 1, "There should be only one argument, but there were \(arguments.count)." )
            XCTAssert( argType == tidyFormatType_STRING, "Expected the argument type to be tidyFormatType_STRING." )
            XCTAssert( argFormat == "%s", "Expected the format to be '%s'.")

            switch argType {

            case tidyFormatType_STRING:
                let value = tidyGetArgValueString( tmessage, arguments[0] )
                XCTAssert( value == "</h2>", "The argument was expected was not \(value)." )

            case tidyFormatType_UINT:
                let _ = tidyGetArgValueUInt( tmessage, arguments[0] )
                XCTFail( "The argument type was not expected!" )

            case tidyFormatType_INT:
                let _ = tidyGetArgValueInt( tmessage, arguments[0] )
                XCTFail( "The argument type was not expected!" )

            case tidyFormatType_DOUBLE:
                let _ = tidyGetArgValueDouble( tmessage, arguments[0] )
                XCTFail( "The argument type was not expected!" )

            default:
                XCTFail( "The argument type was not expected!" )

            }

            /* Return false to indicate that we've handled the message and
               that Tidy needs to take no action with it. */
            return false
        })


        /* This should cause at least one message to arrive at the callback. */
        let _ = tidySetLanguage( "en" )
        let _ = tidyOptSetValue( tdoc, TidyBodyOnly, "true" )
        let _ = tidyParseString( tdoc, "<÷h1>hello, world</h2>" )

        /* Issue the assert here if the callback doesn't fire at least once. */
        wait(for: [callbackSuccess], timeout: 1.0)
    }


    /*************************************************************************
      SwLibTidy adds a feature to Tidy that can avoid all of the message
      callback and nested APIs. The tidyMessageRecords() function provides
      an instance of a class or structure that captures all of the message
      related information into a nice, easy to use structure.

      - tidyMessageRecords()
     *************************************************************************/
    func test_tidyMessageRecords() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        let _ = tidyParseString( tdoc, "<h1>hello, world</h2>")
        let records = tidyMessageRecords(forTidyDoc: tdoc )
        dump( records )

        var expect: String

        XCTAssert( records.count > 0, "Expected to have some tidyMessageRecords." )

        expect = "INSERTING_TAG"
        XCTAssert( records[1].messageKey == expect, "Expected the second record to be \"\(expect)\", but it wasn't." )

        expect = "body"
        XCTAssert( records[1].messageArguments[0].valueString == expect, "Expected the first argument value \"\(expect)\", but it wasn't." )
    }


    /*************************************************************************
      Tidy provides a simple pretty pretter callback and a convenience
      function (for avoiding a callback) that can be used to track the
      progress of the pretty printing process. It correlates (as best as is
      possible) where location of source document components in the tidied
      document. This might be useful, for example, in scrolling before and
      after documents in a synchronized fashion.

      - tidySetPrettyPrinterCallback()
      - tidyPPProgressRecords()
     *************************************************************************/
    func test_pppCallback() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        /* Setup the asynchronous test expectation. */
        let callbackSuccess = XCTestExpectation(description: "The callback should execute at least once.")

        /* Closures can be used as callbacks, which is what we do here. */
        let _ = tidySetPrettyPrinterCallback( tdoc, { tdoc, line, col, destLine in

            callbackSuccess.fulfill()
        })


        /* Tidy and Pretty Print a Document */
        let outpBuffer = SwTidyBuffer()
        let _ = tidySample( doc: tdoc )
        let _ = tidyCleanAndRepair( tdoc )
        let _ = tidySaveBuffer( tdoc, outpBuffer ) /* does the printing */

        /* Issue the assert here if the callback doesn't fire at least once. */
        wait(for: [callbackSuccess], timeout: 1.0)

        /* Pretty printing would have triggered the callback, so that's
           tested. Let's have a look at the tidyPPProgresRecords(). */
        let records = tidyPPProgressRecords( forTidyDoc: tdoc )
        dump( records )

        XCTAssert( records.count > 0, "Expected to have some tidyPPProgress records." )

        XCTAssert( records[4].sourceLine == 5, "Expected sourceLine to be 2." )
        XCTAssert( records[4].sourceColumn == 1, "Expected sourceColumn to be 1." )
        XCTAssert( records[4].destLine == 4, "Expected destLine to be 4." )
    }


    /*************************************************************************
      With all of this talk of callbacks, SwLibTidy also supports traditional
      delegates, so you have an additional option. This test ensures that all
      of the delegates are working just as well as the callbacks.

      - setDelegate()
     *************************************************************************/
    func test_setDelegate() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        let sampleDelegate = SampleTidyDelegate()

        /* Set the delegate, and setup the expections. */
        tidySetDelegate( anObject: sampleDelegate, forTidyDoc: tdoc )
        sampleDelegate.asyncTidyReportsUnknownOption = XCTestExpectation( description: "The delegate should execute at least once." )
        sampleDelegate.asyncTidyReportsOptionChanged = XCTestExpectation( description: "The delegate should execute at least once." )
        sampleDelegate.asyncTidyReportsMessage = XCTestExpectation( description: "The delegate should execute at least once." )
        sampleDelegate.asyncTidyReportsPrettyPrinting =  XCTestExpectation( description: "The delegate should execute at least once." )

        /* Tidy and Pretty Print a Document */
        let outpBuffer = SwTidyBuffer()
        let _ = tidySample( doc: tdoc, useConfig: true )
        let _ = tidyCleanAndRepair( tdoc )
        let _ = tidySaveBuffer( tdoc, outpBuffer ) /* does the printing */

        /* Issue the asserts here if the callback doesn't fire at least once. */
        wait(for: [(sampleDelegate.asyncTidyReportsUnknownOption)!], timeout: 1.0)
        wait(for: [(sampleDelegate.asyncTidyReportsOptionChanged)!], timeout: 1.0)
        wait(for: [(sampleDelegate.asyncTidyReportsMessage)!], timeout: 1.0)
        wait(for: [(sampleDelegate.asyncTidyReportsPrettyPrinting)!], timeout: 1.0)
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        var errBuffer = SwTidyBuffer()
        let _ = tidySetErrorBuffer( tdoc, errbuf: errBuffer )
        let _ = tidySample( doc: tdoc, useConfig: false )
        print( "-----errBuffer after Tidy" )
        print( errBuffer.StringValue() ?? "Oops" )
        var expect = "line 1 column 1 - Warning: missing"
        XCTAssert( errBuffer.StringValue()?.hasPrefix( expect ) ?? false, "Expected the buffer to start with something else." )

        errBuffer = SwTidyBuffer()
        let _ = tidySetErrorBuffer( tdoc, errbuf: errBuffer )
        let _ = tidyCleanAndRepair( tdoc )
        print( "-----errBuffer after clean and repair" )
        print( errBuffer.StringValue() ?? "Oops" )
		expect = "line 1 column 1 - Warning: <div> proprietary attribute"
        XCTAssert( errBuffer.StringValue()?.hasPrefix( expect) ?? false, "Expect nothing to be added to the buffer." )

        errBuffer = SwTidyBuffer()
        let _ = tidySetErrorBuffer( tdoc, errbuf: errBuffer )
        let _ = tidyReportDoctype( tdoc )
        print( "-----errBuffer after report doc type" )
        print( errBuffer.StringValue() ?? "Oops" )
        expect = "Info: Document content looks like HTML5"
        XCTAssert( errBuffer.StringValue()?.hasPrefix( expect ) ?? false, "Expected the buffer to start with something else." )

        errBuffer = SwTidyBuffer()
        let _ = tidySetErrorBuffer( tdoc, errbuf: errBuffer )
        let _ = tidyRunDiagnostics( tdoc )
        print( "-----errBuffer after run diagnostics" )
        print( errBuffer.StringValue() ?? "Oops" )
        expect = "Tidy found 7 warnings and 0 errors!\n\n"
        XCTAssert( errBuffer.StringValue()?.hasSuffix( expect ) ?? false, "Expected the buffer to end with something else." )
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        let _ = tidySample( doc: tdoc, useConfig: false )

        /*
         Save to a buffer, which a lot of tests already do, too.
         */
        let outbuff = SwTidyBuffer()
        let _ = tidySaveBuffer( tdoc, outbuff )
        if let result = outbuff.StringValue() {
            print( "-----outbuff after tidying:" )
            print( result )
            XCTAssert( result.hasPrefix( "<html>\n" ), "The document does not look as expected." )
        } else {
            XCTFail( "The output buffer was empty!" )
        }


        /*
         Save and check a physical file.
         */

        /* Setup error file -- assume we have permissions for tmp file. */
        let outfile = "\(NSTemporaryDirectory())\(NSUUID().uuidString).txt"
        let outURL = URL(fileURLWithPath: outfile)
        var io_err = tidySaveFile( tdoc, outfile )
        if io_err != 1 {
            XCTFail( "tidySaveFile() unsuccessful for '\(outfile)', received error \(io_err)." )
            return
        }

        /* Read the beginning of the file to ensure it matches our expections. */
        do {
            let expects = "<html>\n"
            let result = try String(contentsOf: outURL, encoding: .utf8)
            print( "-----file as read in:" )
            print( result )
            XCTAssert( result.hasPrefix( expects ), "The file did not have the content expected." )
        }
        catch {
            XCTFail( "Could not read '\(outfile)'." )
        }


        /*
         Save to stdout, but hijack stdout so we can check it.
         */

        /* Redirect a file to stdout, so we can test tidyParseStdin(). */
        let fp = freopen( outfile, "w", stdout )
        io_err = tidySaveStdout( tdoc )
        fclose( fp )
        if io_err != 1 {
            XCTFail( "tidySaveStdout() unsuccessful, received error \(io_err)." )
            return
        }

        /* Read the beginning of the file to ensure it matches our expections. */
        do {
            let expects = "<html>\n"
            let result = try String(contentsOf: outURL, encoding: .utf8)
            print( "-----file as read in:" )
            print( result )
            XCTAssert( result.hasPrefix( expects ), "The file did not have the content expected." )
        }
        catch {
            XCTFail( "Could not read '\(outfile)'." )
        }
    }


    /*************************************************************************
      Tidy supports saving configuration files directly, however it only
      writes from a given document's configuration, and only for options that
      have non-default values (it's trivial to do this yourself anyway).

      - tidyOptSaveFile()
     *************************************************************************/
    func test_tidyOptSave() {

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }


        /* Change some config options, because only non-defaults are written. */
        let _ = tidyOptSetValue( tdoc, TidyBlockTags, "one two three four")

        /* Setup output file -- assume we have permissions for tmp file. */
        let outfile = "\(NSTemporaryDirectory())\(NSUUID().uuidString).txt"
        let outURL = URL(fileURLWithPath: outfile)
        let io_err = tidyOptSaveFile( tdoc, outfile )
        if io_err != 0 {
            XCTFail( "tidyOptSaveFile() unsuccessful for '\(outfile)', received error \(io_err)." )
            return
        }

        /* Read the beginning of the file to ensure it matches our expections. */
        do {
            let expects = "new-blocklevel-tags: one, two, three, four"
            let result = try String(contentsOf: outURL, encoding: .utf8)
            print( "-----file as read in:" )
            print( result )
            XCTAssert( result.hasPrefix( expects ), "The file did not have the content expected." )
        }
        catch {
            XCTFail( "Could not read '\(outfile)'." )
        }
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        let _ = tidySample( doc: tdoc )

        if let node = tidyGetRoot( tdoc ) {
            XCTAssert( tidyNodeGetName( node ) == "", "Expected an empty string, got '\(tidyNodeGetName( node ))'." )
        } else {
            XCTFail( "We should have gotten a node." )
        }

        if let node = tidyGetHtml( tdoc ) {
            XCTAssert( tidyNodeGetName( node ) == "html", "Expected 'html', got '\(tidyNodeGetName( node ))'." )
        } else {
            XCTFail( "We should have gotten a node." )
        }

        if let node = tidyGetHead( tdoc ) {
            XCTAssert( tidyNodeGetName( node ) == "head", "Expected 'head'', got '\(tidyNodeGetName( node ))'." )
        } else {
            XCTFail( "We should have gotten a node." )
        }

        guard let bodynode = tidyGetBody( tdoc ) else {
            XCTFail( "We should have gotten a node." )
            return
        }
        XCTAssert( tidyNodeGetName( bodynode ) == "body", "Expected 'body', got '\(tidyNodeGetName( bodynode ))'." )

        guard let divnode = tidyGetChild( bodynode ) else {
            XCTFail( "We should have gotten a node." )
            return
        }
        XCTAssert( tidyNodeGetName( divnode ) == "div", "Expected 'div', got '\(tidyNodeGetName( divnode ))'." )

        guard let pnode = tidyGetNext( divnode ) else {
			XCTFail( "We should have gotten a node." )
			return
		}
		XCTAssert( tidyNodeGetName( pnode ) == "p", "Expected 'p', got '\(tidyNodeGetName( divnode ))'." )

		guard let divnode_again = tidyGetPrev( pnode ) else {
			XCTFail( "We should gotten a node again." )
			return
		}
		XCTAssert( tidyNodeGetName( divnode_again ) == "div", "Expected 'div', got '\(tidyNodeGetName( divnode_again ))'." )

		guard let bodynode_again = tidyGetParent( divnode_again ) else {
			XCTFail( "We should gotten a node again." )
			return
		}
		XCTAssert( tidyNodeGetName( bodynode_again ) == "body", "Expected 'body', got '\(tidyNodeGetName( bodynode_again ))'." )

		let _ = tidyDiscardElement( tdoc, pnode )

		/* We've deleted the pnode, so let's check the result to make sure
           that it's really gone. */

		let docBuffer = SwTidyBuffer()
		let _ = tidySaveBuffer( tdoc, docBuffer )

		if let docString = docBuffer.StringValue() {
			let result = docString.range( of: "This is a paragraph" )
			print( docString )
			XCTAssert( result == nil, "The substring is still in the document." )
		} else {
			XCTFail( "The document string was empty for some reason." )
		}
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        let _ = tidySample( doc: tdoc )

		guard
			let bodynode = tidyGetBody( tdoc ),
			let divnode = tidyGetChild( bodynode ) else {
				XCTFail( "Unable to get the required node from the sample." )
				return
		}

		/* Build an array of attributes on the div. */
		var attrs: [TidyAttr] = []
		var attr = tidyAttrFirst( divnode )
		while attr != nil {
			attrs.append( attr! )
			attr = tidyAttrNext( attr! )
		}
		XCTAssert( attrs.count == 4, "There should have been 4 attributes, but counted \(attrs.count).")

		attr = attrs[0]
        if let attr = attr {
            XCTAssert( tidyAttrName( attr ) == "id", "Expected 'id'." )
            XCTAssert( tidyAttrValue( attr ) == "", "Expected an empty string." )
            XCTAssert( tidyAttrGetId( attr ) == TidyAttr_ID, "Expected 'TidyAttr_ID'." )
            XCTAssert( tidyAttrIsEvent( attr ) == false, "Expect this to be false." )
        }

		attr = attrs[2]
        if let attr = attr {
            XCTAssert( tidyAttrName( attr ) == "onclick", "Expected 'onclick'." )
            XCTAssert( tidyAttrValue( attr ) == "someFunction()", "Expected 'someFunction()'." )
            XCTAssert( tidyAttrGetId( attr ) == TidyAttr_OnCLICK, "Expected TidyAttr_OnCLICK." )
            XCTAssert( tidyAttrIsEvent( attr ) == true, "Expect this to be true." )
        }

        if let attr = tidyAttrGetById( divnode, TidyAttr_CLASS ) {
			XCTAssert( tidyAttrValue( attr ) == "high", "Expected 'high'." )
		}

		if let _ = tidyAttrGetById( divnode, TidyAttr_DATA ) {
			XCTFail( "The data attribute was found, which is strange." )
		}

		/* Now discard an attribute. */
		attr = attrs[3]
		tidyAttrDiscard( tdoc, divnode, attr! )

		let docBuffer = SwTidyBuffer()
		let _ = tidySaveBuffer( tdoc, docBuffer )

		if let docString = docBuffer.StringValue() {
			let result = docString.range( of: "idl" )
			print( docString )
			XCTAssert( result == nil, "The attibute is still in the document." )
		} else {
			XCTFail( "The document string was empty for some reason." )
		}
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

        guard
            let tdoc = tidyCreate()
        else { XCTFail( TidyCreateFailed ); return }
        defer { tidyRelease( tdoc ) }

        /* We will Tidy with TidyIndentContent enabled for pretty printing. */
        let _ = tidyOptSetInt( tdoc, TidyIndentContent, TidyYesState.rawValue )
        let _ = tidySample( doc: tdoc )

        guard
            let bodynode = tidyGetBody( tdoc ),
            let divnode = tidyGetChild( bodynode ),
            let h1node = tidyGetChild( divnode ),
            let h1text = tidyGetChild( h1node ) else {
                XCTFail( "Unable to get the required nodes from the sample." )
                return
        }

        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( bodynode ) )
        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( divnode ) )
        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( h1node ) )
        JSDAssertEqual( TidyNode_Text,  tidyNodeGetType( h1text ) )

        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( bodynode ) )
        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( divnode ) )
        JSDAssertEqual( TidyNode_Start, tidyNodeGetType( h1node ) )
        JSDAssertEqual( TidyNode_Text,  tidyNodeGetType( h1text ) )

        JSDAssertEqual( "body", tidyNodeGetName( bodynode ) )
        JSDAssertEqual( "div",  tidyNodeGetName( divnode ) )
        JSDAssertEqual( "h1",   tidyNodeGetName( h1node ) )
        JSDAssertEqual( "",     tidyNodeGetName( h1text ) )

        JSDAssertEqual( false, tidyNodeIsText( bodynode ) )
        JSDAssertEqual( false, tidyNodeIsText( divnode ) )
        JSDAssertEqual( false, tidyNodeIsText( h1node ) )
        JSDAssertEqual( true,  tidyNodeIsText( h1text ) )

        JSDAssertEqual( false, tidyNodeIsProp( tdoc, bodynode ) )
        JSDAssertEqual( false, tidyNodeIsProp( tdoc, divnode ) )
        JSDAssertEqual( false, tidyNodeIsProp( tdoc, h1node ) )
        JSDAssertEqual( false, tidyNodeIsProp( tdoc, h1text ) )

        JSDAssertEqual( false, tidyNodeHasText( tdoc, bodynode ) )
        JSDAssertEqual( false, tidyNodeHasText( tdoc, divnode ) )
        JSDAssertEqual( false, tidyNodeHasText( tdoc, h1node ) )
        JSDAssertEqual( true,  tidyNodeHasText( tdoc, h1text ) )


        var buffer: SwTidyBuffer
        var expect: String
        var result: String

        buffer = SwTidyBuffer()
        expect = "<body>"
        XCTAssert( tidyNodeGetText( tdoc, bodynode, buffer ), "Unable to get bodynode text." )
        printhr( buffer.StringValue(), "tidyNodeGetText() bodynode" )
        JSDAssertHasPrefix( expect, buffer.StringValue() )

        buffer = SwTidyBuffer()
        expect = "<h1>\n  Hello, world!\n</h1>"
        XCTAssert( tidyNodeGetText( tdoc, h1node, buffer ), "Unable to get h1node text." )
        printhr( buffer.StringValue(), "tidyNodeGetText() h1node" )
        JSDAssertHasPrefix( expect, buffer.StringValue() )

        /* We'll use the convenience version of tidyNodeGetText() this time. */
        expect = "Hello, world!"
        result = tidyNodeGetText( tdoc, h1text )
        printhr( result, "tidyNodeGetText() h1text" )
        JSDAssertHasPrefix( expect, result )


        buffer = SwTidyBuffer()
        XCTAssert( tidyNodeGetValue( tdoc, bodynode, buffer ) == false, "This node shouldn't have a value." )

        buffer = SwTidyBuffer()
        expect = "Hello, world!"
        XCTAssert( tidyNodeGetValue( tdoc, h1text, buffer ), "This node should have a value." )
        printhr( buffer.StringValue(), "tidyNodeGetValue() h1text" )
        JSDAssertHasPrefix( expect, buffer.StringValue() )

        /* Use the convenience version of tidyNodeGetValue(). */
        if let _ = tidyNodeGetValue( tdoc, divnode ) {
            XCTFail( "This node shouldn't have a value." )
        }

        if let _ = tidyNodeGetValue( tdoc, h1node ) {
            XCTFail( "This node shouldn't have a value." )
        }

        if let result = tidyNodeGetValue( tdoc, h1text ) {
            expect = "Hello, world!"
            print( result, "tidyNodeGetValue() h1text" )
            JSDAssertHasPrefix( expect, result )
        } else {
            XCTFail( "We should have gotten text here." )
        }

        XCTAssert( tidyNodeGetId( bodynode ) == TidyTag_BODY,    "Expected TidyTag_BODY." )
        XCTAssert( tidyNodeGetId( divnode ) ==  TidyTag_DIV,     "Expected TidyTag_DIV." )
        XCTAssert( tidyNodeGetId( h1node ) ==   TidyTag_H1,      "Expected TidyTag_H1." )
        XCTAssert( tidyNodeGetId( h1text ) ==   TidyTag_UNKNOWN, "Expected TidyTag_UNKNOWN." )

        JSDAssertEqual( 1, tidyNodeLine( bodynode ) )
        JSDAssertEqual( 1, tidyNodeLine( divnode ) )
        JSDAssertEqual( 2, tidyNodeLine( h1node ) )
        JSDAssertEqual( 2, tidyNodeLine( h1text ) )

        JSDAssertEqual( 1, tidyNodeColumn( bodynode ) )
        JSDAssertEqual( 1, tidyNodeColumn( divnode ) )
        JSDAssertEqual( 3, tidyNodeColumn( h1node ) )
        JSDAssertEqual( 7, tidyNodeColumn( h1text ) )
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

        var expects: String

        /*
         The singular for the given message. Because the current locale is
         the default locale, we get same result as tidyDefaultString().
         */
        expects = tidyLocalizedString( STRING_ERROR_COUNT_ERROR )
        JSDAssertEqual( expects, "error" )

        /*
         The form of the message if there are five of whatever we're looking
         for. There are only a few plural strings used in Tidy.
         */
        expects = tidyLocalizedStringN( STRING_ERROR_COUNT_ERROR, 5 )
        JSDAssertEqual( expects, "errors" )

        /* Let's set the language and lookup a French string. */
        let _ = tidySetLanguage("fr")

        expects = tidyLocalizedString( STRING_SPECIFIED )
        JSDAssertEqual( expects, "précisé" )

        /*
         Oops! We want a TidyReportLevel as a string! This works for any of
         the other types that have strings defined, too. And if we're in
         French, we should get the English string anyway.
         */
        expects = tidyDefaultString( tidyStrings.init( TidyInfo.rawValue) )
        JSDAssertEqual( expects, "Info: " )

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
