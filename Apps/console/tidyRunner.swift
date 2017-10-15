//
//  tidyRunner.swift
//  console
//
//  Created by Jim Derry on 10/14/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy


/*
 Will be used as the callback for unknown configuration options.
 We're just generating output to confirm that the method was called, but
 we should be looking at the tdoc's app data to call a method in our class.
 */
public func configurationCallback( tdoc: TidyDoc, option: String, value: String) -> Swift.Bool {
    print("\(option) \(value)")
    return false
}


/*
 Will be used as the callback for messages emitted by Tidy.
 We're just generating output to confirm that the method was called, but
 we should be looking at the tdoc's app data to call a method in our class.
 */
public func messageCallback( _ tmessage: TidyMessage ) -> Bool {
    print("The message callback")
    return true
}


/*
 This class simply makes it possible to run the same tests in multiple
 targets. Most of this functionality should be migrated to the unit tests,
 but sometimes it's nice simply to see output during development.
 */
class TidyRunner {

    /* Replace this function if you don't want to use print() */
    public var output: ( String ) -> Void = { arg in
        print(arg)
    }

    /* Just a string for a horizontal rule. */
    private var horizontal_rule = "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

    /* Execute some tests to make sure the library is working. */
    public func RunTidy() {

        /* Create a TidyDoc */
        guard let tdoc = tidyCreate() else { return }


        /*
         Store a reference to self in our document. Callbacks cannot call
         back into an instance method, but the top-level method will be able
         to look at this value, and call into the instance method with it.
         */
        tidySetAppData(tdoc, self)


        /* We're going to capture Tidy's reporting output in this buffer. */
        let errorBuffer = TidyBuffer()
        _ = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )


        /*
         Let's set our callbacks. These *must* be outside of this class,
         although a closure should work, too.
         */
        _ = tidySetMessageCallback( tdoc, filtCallback: messageCallback)
        let _ = tidySetConfigCallback(tdoc, configurationCallback)


        /*
         Let's load a configuration file.
         This is broken, because ideally we'd load it from a bundle, but
         console applications don't have bundles, so I need to work this out.
         */
        let configFile = "~/Development/tidy-cocoa/_test_files/sample_01.cfg"
        let _ = tidyLoadConfig(tdoc, configFile)


        /* Let's parse a string, and check the status. */
        _ = tidyParseString( tdoc, "Hello, world")
        output("After parsing a simple string, tidyStatus is \(tidyStatus(tdoc))")

        /* Try out tidyDetectedXhtml — NEED TO PROCESS A DOCUMENT FIRST */
        output(horizontal_rule)
        output("tidyDetectedXhtml is \(tidyDetectedXhtml(tdoc))")

        /* These will be added to our buffer, and not output yet. */
        tidyErrorSummary(tdoc)
        tidyGeneralInfo(tdoc)

        /* Let's output the error buffer now. */
        output(horizontal_rule)
        output(errorBuffer.StringValue() ?? "MISSING!")

        /* Display the results of the picklist of the first option. */
        let myOpts = tidyGetOptionList( tdoc )
        output(horizontal_rule)
        output( "\(tidyOptGetPickList(myOpts[0]))" )

        /* Show the locale information. */
        output(horizontal_rule)
        output( tidySystemLocale() )

        /* Let's show what happened during the configuration phase. */
        output(horizontal_rule)
        output( "\(tidyConfigRecords(forTidyDoc: tdoc))" )

        /* Don't need this any more. */
        tidyRelease( tdoc )
    }


}
