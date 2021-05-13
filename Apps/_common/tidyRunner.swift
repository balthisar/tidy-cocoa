//
//  tidyRunner.swift
//  console, gui, ios
//
//  Created by Jim Derry on 10/14/17.
//  Copyright © 2017-2021 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy

/**
 *  Will be used as the callback for messages emitted by Tidy. In this case, the
 *  callback is to a top-level function. It's a good example of getting the app
 *  data: in this case, we'll use the  TidyRunner's output routine.
 */
public func messageCallback(_ message: SwLibTidyMessageProtocol) -> Bool {
    if let owner = tidyGetAppData(message.document) as? TidyRunner {
        owner.output("(messageCallback()) \(message.messageOutputDefault)")
    } else {
        print("Hmmm... there's no app data assigned, so this shouldn't happen.")
    }

    return true
}

/**
 *  This class simply makes it possible to run the same tests in multiple
 *  targets. Most of this functionality should be migrated to the unit tests,
 *  but sometimes it's nice simply to see output during development.
 */
class TidyRunner {
    /* Replace this variable's closure if you don't want to use print().
     * For example, the GUI demos use this class as well, and direct output
     * to the text views.
     */
    public var output: (String) -> Void = { arg in
        print(arg)
    }

    /* Saves the result of the pretty printer progress callback for us. */
    public var pppList: String = ""

    /* Just a string for a horizontal rule. */
    private var horizontal_rule = "\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"

    /* This will be our pretty printer progress callback. Apparently since
     * Swift 3, this is safe to do now.
     */
    private func ppCallback(_ report: SwLibTidyPPProgressProtocol) {
        pppList += "Source Line: \(report.sourceLine), Col: \(report.sourceColumn); Destination Line: \(report.destLine)\n"
    }

    /* Execute some tests to make sure the library is working. */
    public func RunTidy() {
        /* Show version and release information. */
        output("LibTidy version is \(tidyLibraryVersion()).")
        output("LibTidy release date is \(tidyReleaseDate()).")
        output("LibTidy platform is \(tidyPlatform()).")
        output(horizontal_rule)

        /* Create a TidyDoc */
        output("tidyCreate()")
        guard let tdoc = tidyCreate() else { return }

        /* Store a reference to self in our document. Callbacks cannot call
         * back into an instance method, but the top-level method will be able
         * to look at this value, and call into an instance method with it.
         */
        output("tidySetAppData()")
        tidySetAppData(tdoc, self)

        /* We're going to capture Tidy's reporting output in this buffer. */
        output("SwLibTidyBuffer()")
        let errorBuffer = SwLibTidyBuffer()
        output("tidySetErrorBuffer()")
        _ = tidySetErrorBuffer(tdoc, errbuf: errorBuffer)

        output("SwLibTidyBuffer()")
        /* We're going to capture Tidy's document output in this buffer. */
        let docBuffer = SwLibTidyBuffer()

        /* Let's set our pretty printer progress callback. In this case, we will
         * set it to an instance method. Apparently since Swift 3, this is safe
         * to do now.
         */
        output("tidySetPrettyPrinterCallback()")
        _ = tidySetPrettyPrinterCallback(tdoc, ppCallback)

        /* Let's set our message callback. If using a function, as here, then it
         * should be outside of this class, i.e., a top-level function.
         */
        output("tidySetMessageCallback()")
        _ = tidySetMessageCallback(tdoc, messageCallback)

        /* Let's set our unknown configuration option callback. In this case,
         * we'll use a closure so that we don't have to define a top-level
         * function.
         * It's a good example of getting the app data: in this case, we'll use
         * the TidyRunner's output routine. Remember, this is a closure, so no
         * context is available; it's essentially outside of any instances of
         * this class.
         */
        output("tidySetConfigCallback()")
        _ = tidySetConfigCallback(tdoc) { (report: SwLibTidyConfigReportProtocol) -> Swift.Bool in

            self.output("tidyGetAppData()")
            if let owner = tidyGetAppData(report.document) as? TidyRunner {
                owner.output("(configClosure) \(report.option) \(report.value)")
            } else {
                print("Hmmm... there's no app data assigned, and this shouldn't happen.")
            }
            return false
        }

        /* This class is used in a demo app only, so we're going to assume that
         * the files we need are located in the bundle. For CLI applications,
         * Cocoa treats the executable's containing directory as the bundle,
         * so simply copying the files to the Products directory for the CLI
         * application will work.
         */

        /* Let's load a configuration file, which we've stored in the bundle. */
        if let file = Bundle.main.path(forResource: "case-001", ofType: "conf") {
            output("tidyLoadConfig()")
            _ = tidyLoadConfig(tdoc, file)
        } else {
            print("The sample files should be in the bundle or adjacent to the executable, but weren't found.")
        }
        output(horizontal_rule)

        /* Let's parse an HTML file, and check the status. */
        if let file = Bundle.main.path(forResource: "case-001", ofType: "html") {
            output("tidyParseFile()")
            _ = tidyParseFile(tdoc, file)
            output("After parsing a simple string, tidyStatus is \(tidyStatus(tdoc))")
        } else {
            output("Couldn't find the HTML file for some reason; aborting remaining program.")
            return
        }

        /* Try out tidyDetectedXhtml — NEED TO PROCESS A DOCUMENT FIRST,
         * otherwise the library fails with EXC_BAD_ACCESS because the lexer
         * is NULL. This needs to be fixed upstream.
         */
        output(horizontal_rule)
        output("tidyDetectedXhtml()")
        output("tidyDetectedXhtml is \(tidyDetectedXhtml(tdoc))")

        /* These will be added to our buffer, and not output yet. However
         * the callback will output the messages they generate.
         */
        output(horizontal_rule)
        output("tidyErrorSummary()")
        tidyErrorSummary(tdoc)
        output("tidyGeneralInfo()")
        tidyGeneralInfo(tdoc)

        /* Let's output the error buffer now. */
        output(horizontal_rule)
        output("errorBuffer.StringValue()")
        output(errorBuffer.StringValue() ?? "MISSING!")

        /* Let's output the Tidy'd document now. */
        output(horizontal_rule)
        _ = tidySaveBuffer(tdoc, docBuffer)
        output("docBuffer.StringValue()")
        output(docBuffer.StringValue() ?? "MISSING!")

        /* Display the pretty printing list generated in the callback. */
        output(horizontal_rule)
        output("pppList contents")
        output(pppList)

        /* Display the results of the picklist of the first option. */
        output(horizontal_rule)
        output("tidyGetOptionList()")
        let myOpts = tidyGetOptionList(tdoc)
        output("tidyOptGetPickList()")
        output("\(tidyOptGetPickList(myOpts[0]))")

        /* Let's show what happened during the configuration phase. */
        output(horizontal_rule)
        for record in tidyConfigRecords(forTidyDoc: tdoc) {
            output("(tidyConfigRecords()) option '\(record.option)' and value '\(record.value)'")
        }

        /* Don't need this any more. */
        output("tidyRelease()")
        tidyRelease(tdoc)

        output(horizontal_rule)
    }
}
