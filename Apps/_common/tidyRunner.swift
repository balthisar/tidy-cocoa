//
//  tidyRunner.swift
//  console, gui, ios
//
//  Created by Jim Derry on 10/14/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy


/*
 Will be used as the callback for messages emitted by Tidy. In this case, the
 callback is to a top-level function.
 It's a good example of getting the app data: in this case, we'll use the
 TidyRunner's output routine.
 */
public func messageCallback( _ tmessage: TidyMessage ) -> Bool {

    if let owner = tidyGetAppData( tidyGetMessageDoc( tmessage )) as? TidyRunner {
        let string = tidyGetMessageOutputDefault( tmessage )
        owner.output( "** \(string)");
    } else {
        print("Hmmm... there's no app data assigned, so this shouldn't happen.")
    }

    return true
}


/*
 This class simply makes it possible to run the same tests in multiple
 targets. Most of this functionality should be migrated to the unit tests,
 but sometimes it's nice simply to see output during development.
 */
class TidyRunner {

    /*
     Replace this variable's closure if you don't want to use print().
     For example, the GUI demos use this class as well, and direct output
     to the text views.
     */
    public var output: ( String ) -> Void = { arg in
        print(arg)
    }

    /* Saves the result of the pretty printer progress callback for us. */
    public var pppList: String = ""

    /* Just a string for a horizontal rule. */
    private var horizontal_rule = "\n=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"

    /*
     This will be our pretty printer progress callback. Apparently since
     Swift 3, this is safe to do now.
     */
    private func ppCallback( _ tdoc: TidyDoc, _ line: UInt, _ col: UInt, _ destLine: UInt ) -> Void {
        self.pppList += "Source Line: \(line), Col: \(col); Destination Line: \(destLine)\n"
    }


    /* Execute some tests to make sure the library is working. */
    public func RunTidy() {

        /* Show version and release information. */
        output( "LibTidy version is \(tidyLibraryVersion()).")
        output( "LibTidy release date is \(tidyReleaseDate()).")
        output( "LibTidy platform is \(tidyPlatform() ?? "None").")
        output(horizontal_rule)


        /* Create a TidyDoc */
        guard let tdoc = tidyCreate() else { return }


        /*
         Store a reference to self in our document. Callbacks cannot call
         back into an instance method, but the top-level method will be able
         to look at this value, and call into an instance method with it.
         */
        tidySetAppData(tdoc, self)


        /* We're going to capture Tidy's reporting output in this buffer. */
        let errorBuffer = TidyBuffer()
        let _ = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )

        /* We're going to capture Tidy's document output in this buffer. */
        let docBuffer = TidyBuffer()


        /*
         Let's set our message callback. If using a function, as here, then it
         should be outside of this class, i.e., a top-level function. Although
         callbacks to instance methods are allowed since Swift 3, it's still
         better to segregate out of context information external to the
         instance.
         */
        let _ = tidySetMessageCallback( tdoc, filtCallback: messageCallback)

        /*
         Let's set our unknown configuration option callback. In this case,
         we'll use a closure so that we don't have to define a top-level
         function.
         It's a good example of getting the app data: in this case, we'll use
         the TidyRunner's output routine. Remember, this is a closure, so no
         context is available; it's essentially outside of any instances of
         this class.
         */
        let _ = tidySetConfigCallback( tdoc, { (tdoc: TidyDoc, option: String, value: String) -> Swift.Bool in

            if let owner = tidyGetAppData( tdoc ) as? TidyRunner {
                owner.output( "\(option) \(value)" );
            } else {
                print("Hmmm... there's no app data assigned, so this shouldn't happen.")
            }
            return false
        })

        /*
         Let's set our pretty printer progress callback. In this case, we will
         set it to an instance method. Apparently since Swift 3, this is safe
         to do now.
         */
        let _ = tidySetPrettyPrinterCallback( tdoc, self.ppCallback)


        /* Let's load a configuration file, which we've store in the bundle. */
        if let file = Bundle.main.path(forResource: "case-001", ofType: "conf") {
            let _ = tidyLoadConfig(tdoc, file)
        }
        output(horizontal_rule)


        /* Let's parse an HTML file, and check the status. */
        if let file = Bundle.main.path(forResource: "case-001", ofType: "html") {
            _ = tidyParseFile( tdoc, file )
            output("After parsing a simple string, tidyStatus is \(tidyStatus(tdoc))")
        } else {
            output("Couldn't find the HTML file for some reason.")
        }

        /* Try out tidyDetectedXhtml — NEED TO PROCESS A DOCUMENT FIRST */
        output(horizontal_rule)
        output("tidyDetectedXhtml is \(tidyDetectedXhtml(tdoc))")

        /*
         These will be added to our buffer, and not output yet. However
         the callback will output the messages they generate.
         */
        output(horizontal_rule)
        tidyErrorSummary(tdoc)
        tidyGeneralInfo(tdoc)

        /* Let's output the error buffer now. */
        output(horizontal_rule)
        output(errorBuffer.StringValue() ?? "MISSING!")

        /* Let's output the Tidy'd document now. */
        output(horizontal_rule)
        let _ = tidySaveBuffer( tdoc, docBuffer )
        output(docBuffer.StringValue() ?? "MISSING!")

        /* Display the pretty printing list generated in the callback. */
        output(horizontal_rule)
        output(pppList)

        /* Display the results of the picklist of the first option. */
        let myOpts = tidyGetOptionList( tdoc )
        output(horizontal_rule)
        output( "\(tidyOptGetPickList(myOpts[0]))" )

        /* Show the locale information. */
        output(horizontal_rule)
        output( "The current locale is \(tidySystemLocale())." )

        /* Let's show what happened during the configuration phase. */
        output(horizontal_rule)
        output( "\(tidyConfigRecords(forTidyDoc: tdoc))" )

        /* Don't need this any more. */
        tidyRelease( tdoc )

        output(horizontal_rule)
    }


}