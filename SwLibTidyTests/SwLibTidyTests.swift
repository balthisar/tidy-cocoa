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
    
    private var tdoc: TidyDoc?      // used for most tests, assigned in setUp()
    private var testBundle: Bundle?  // reference to the test case bundle


    override func setUp() {
        super.setUp()
        testBundle = Bundle(for: type(of: self))
        tdoc = tidyCreate()!
    }
    
    
    override func tearDown() {
        tidyRelease( tdoc! )
        super.tearDown()
    }


    /* Many of our tests require Tidy to Tidy a file first. */
    func tidy( doc: TidyDoc, file: String, config: String? = nil) -> Swift.Bool {

        if let config = config {
            if let file = testBundle!.path(forResource: config, ofType: "conf") {
                let _ = tidyLoadConfig( doc, file )
            }
        }

        if let file = testBundle!.path(forResource: file, ofType: "html") {
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
            XCTFail ( "Could not create a Tidy document." )
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

      Because we're also testing the encoding version of the configuration
      loader, we'll opportunistically test tidyOptResetAllToDefault().

      - tidyLoadConfig()
      - tidyLoadConfigEnc()
      - tidyOptResetAllToDefault()
     *************************************************************************/
    func test_tidyLoadConfig() {

        if let file = testBundle!.path(forResource: "case-001", ofType: "conf") {

            let _ = tidyLoadConfig( tdoc!, file )
            XCTAssert( tidyOptGetInt( tdoc!, TidyAccessibilityCheckLevel ) == 3, "Expected 3, but got something else." )

            let _ = tidyOptResetAllToDefault( tdoc! )
            XCTAssert( tidyOptGetInt( tdoc!, TidyAccessibilityCheckLevel ) == 0, "Expected 0, but got something else." )

            let _ = tidyLoadConfigEnc( tdoc!, file, "ascii")
            XCTAssert( tidyOptGetInt( tdoc!, TidyAccessibilityCheckLevel ) == 3, "Expected 3, but got something else." )

        } else {
            XCTAssert( false, "Couldn't load the configuration file." )
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
     *************************************************************************/
    func test_tidyParseStuff() {

        let _ = tidyParseString( tdoc!, "<h1>Hello, world!</h2>" )

        XCTAssert( tidyStatus( tdoc! ) == 1, "Expected tidyStatus() == 1" )

        if let file = testBundle!.path(forResource: "case-001", ofType: "html") {
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

        guard let mydoc = tidyCreate() else { return }

        /* Output goes to STDOUT for this. */
        let _ = tidyParseString( mydoc, "<img src='#'>")

        /* Now let's setup error buffers. */
        let errorBuffer = TidyBuffer()
        let err = tidySetErrorBuffer( mydoc, errbuf: errorBuffer )
        XCTAssert( err == 0, "tidySetErrorBuffer() returned \(err) instead of 0.")

        tidyErrorSummary( mydoc )
        tidyGeneralInfo( mydoc )

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
            XCTAssert( false, "The output buffer was empty!" )
        }
    }


    /*************************************************************************
      Tidy offers a cross-platform file exists function, which is good if
      you're writing cross-platform applications. Let's try it out.

      - tidyFileExists()
     *************************************************************************/
    func test_tidyFileExists() {

        if var file = testBundle!.path(forResource: "case-001", ofType: "conf") {

            XCTAssert( tidyFileExists( tdoc!, file ), "File \(file) does not exist." )

            file += ".xfghjkh"

            XCTAssert( !tidyFileExists( tdoc!, file ), "By some strange fluke, file \(file) exists!" )
        }
    }


    /*************************************************************************
      Tidy can work with multiple combinations of input and out character
      encodings. We're not going to test that Tidy actually works, but we
      will test that Tidy accepts our wrapped methods.

      - tidySetCharEncoding()
      - tidySetInCharEncoding()
      - tidySetOutCharEncoding()
      - tidyOptGetInt()
     *************************************************************************/
    func test_tidySetCharEncoding() {

        /* Our default input and output encodings should both be 4: UTF8 */
        var inputVal = tidyOptGetInt( tdoc!, TidyInCharEncoding )
        var outputVal = tidyOptGetInt( tdoc!, TidyOutCharEncoding )

        XCTAssert( inputVal == 4 && outputVal == 4, "The in and out character encoding defaults seem to be wrong.")

        /* tidySetCharEncoding() affects both input and output encodings. */
        let _ = tidySetCharEncoding( tdoc!, "mac")
        inputVal = tidyOptGetInt( tdoc!, TidyInCharEncoding )   // should be 6
        outputVal = tidyOptGetInt( tdoc!, TidyOutCharEncoding ) // should be 1
        XCTAssert( inputVal == 6 && outputVal == 1, "The in and out character encoding settings seem to be wrong.")

        /* Only affect input encoding. */
        let _ = tidySetInCharEncoding( tdoc!, "big5")
        inputVal = tidyOptGetInt( tdoc!, TidyInCharEncoding )   // should be 12
        outputVal = tidyOptGetInt( tdoc!, TidyOutCharEncoding ) // should be 1
        XCTAssert( inputVal == 12 && outputVal == 1, "The in and out character encoding settings seem to be wrong.")

        /* Only affect output encoding. */
        let _ = tidySetOutCharEncoding( tdoc!, "win1252")
        inputVal = tidyOptGetInt( tdoc!, TidyInCharEncoding )   // should be 12
        outputVal = tidyOptGetInt( tdoc!, TidyOutCharEncoding ) // should be 7
        XCTAssert( inputVal == 12 && outputVal == 7, "The in and out character encoding settings seem to be wrong.")
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

        let callbackSuccess = XCTestExpectation(description: "The option callback should execute at least once.")

        let _ = tidySetConfigCallback( tdoc!, { (tdoc: TidyDoc, option: String, value: String) -> Swift.Bool in

            callbackSuccess.fulfill()

            /*
             Return false to indicate that the callback did NOT handle the
             option, so that Tidy can issue a warning.
             */
            return false
        })

        if let file = testBundle!.path(forResource: "case-001", ofType: "conf") {
            let _ = tidyLoadConfig( tdoc!, file )
        } else {
            XCTAssert( false, "Couldn't load the configuration file." )
        }

        /* Issue the assert here if the callback doesn't fire at least once. */
        wait(for: [callbackSuccess], timeout: 1.0)

        /*
         Our sample config should have generated at least one record. Using
         tidyConfigRecords() is an SwLibTidy alternative to using a callback.
         The first unknown configuration record in our sample file should be
         for a proposed option 'mynewconfig'.
         */
        if let firstOption = tidyConfigRecords(forTidyDoc: tdoc! ).first?.option {
            XCTAssert( firstOption == "mynewconfig", "The first bad option is supposed to be 'mynewconfig'." )
        } else {
            XCTAssert( false, "No configuration records exist." )
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
      - tidyOptIsReadOnly()
      - tidyOptGetCategory()
     *************************************************************************/
    func test_tidyOptions_general() {

        guard let tdoc = tdoc else {
            XCTAssert( false, "The test could not be conducted due to guard conditions." )
            return
        }

        let optionList = tidyGetOptionList( tdoc )

        /* Verify that our options list has some options. */
        XCTAssert( optionList.count > 0, "The options list is empty." )

        /*
         Verify that the TidyOptionID for the first item is as expected.
         This test is fragile if LibTidy changes its enum ahead of this item.
         */
        if let optionId = tidyOptGetId( optionList[0] ) {
            XCTAssert( optionId == TidyAccessibilityCheckLevel, "The TidyOptionId is not as expected." )

        } else {
            XCTAssert( false, "The call to tidyOptGetId() was not successful." )
        }


    }

    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test deals with using options' pick lists, which can be an
      introspective source of information, particularly for GUI programs.

      - tidyOptGetPickList()
      - tidyOptGetCurrPick()
     *************************************************************************/


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test deals with all of the ways to get and set options.

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


    /*************************************************************************
      A whole lot of Tidy is dedicated to managing options, and clients will
      want to manage options as well.

      This test demonstrates how documentation for Tidy options can be
      generated.

      - tidyOptGetDoc()
      - tidyOptGetDocLinksList()
     *************************************************************************/


    /*************************************************************************
      When Tidy is used with the gnu-emacs option, it will display its error
      reports in a format that's useful to emacs users. The implementing
      program will have to specify the file and path to be used in this
      modified report.

      - tidySetEmacsFile()
      - tidyGetEmacsFile()
     *************************************************************************/


    /*************************************************************************
      Tidy normally sends message output to STDOUT, which can be useful in
      command line tools, but luckily Tidy supports other types of output,
      as demonstrated in this test.

      - tidySetErrorFile()
      - tidySetErrorBuffer()
     *************************************************************************/


    /*************************************************************************
      Sophisticated programs will want more control over Tidy's message
      output, and the use of the message callback enables this. This test
      demonstrates setting up such a callback.

      - tidySetMessageCallback()
     *************************************************************************/


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


    /*************************************************************************
      SwLibTidy adds a feature to Tidy that can avoid all of the message
      callback and nested APIs. The tidyMessageRecords() function provides
      an instance of a class or structure that captures all of the message
      related information into a nice, easy to use structure.

      - tidyMessageRecords()
     *************************************************************************/


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


    /*************************************************************************
      Tidy is an error correcting HTML parser, so let's learn how to parse.

      - tidyParseFile()
      - tidyParseStdin()
      - tidyParseString()
     *************************************************************************/


    /*************************************************************************
      A parsed document can have additional clean and repair operations
      performed upon it, as well as report some related information about
      the process.

      - tidyCleanAndRepair()
      - tidyRunDiagnostics()
      - tidyReportDocType()
     *************************************************************************/


    /*************************************************************************
      Saving tidied files to different output types is directly supported by
      Tidy, although it's probably more likely you will take advantage of
      macOS-native means. Still, you need to learn how to save to a buffer,
      here.

      - tidySaveFile()
      - tidySaveStdout()
      - tidySaveBuffer()
     *************************************************************************/


    /*************************************************************************
      Tidy supports saving configuration files directly, however it only
      writes from a given document's configuration, and only for options that
      have non-default values (it's trivial to do this yourself anyway).

      - tidyOptSaveFile()
     *************************************************************************/


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


}
