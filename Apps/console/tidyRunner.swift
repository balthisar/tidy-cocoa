//
//  tidyRunner.swift
//  console
//
//  Created by Jim Derry on 10/14/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy

public func someFunc( tdoc: TidyDoc, option: String, value: String) -> Swift.Bool {
    print("\(option) \(value)")
    return false
}


public func myMessageCallback( _ tmessage: TidyMessage ) -> Bool {
    print("The message callback")
    return true
}


class TidyRunner {

    public var output: ( String ) -> Void = { arg in
        print(arg)
    }


    func printHello() {
        output("Hello, says the printHello function.")
    }

    func RunTidy() {

        printHello()

        // Create a TidyDoc
        guard let tdoc = tidyCreate() else { return }

        // Store a reference to self here, so that we can fetch it later.
        tidySetAppData(tdoc, self)

        let errorBuffer = TidyBuffer()
        _ = tidySetErrorBuffer( tdoc, errbuf: errorBuffer )

        // Let's set a message callback
        _ = tidySetMessageCallback( tdoc, filtCallback: myMessageCallback)

        // Let's load a configuration file.
        // Note, eventually copy these to the bundle and load them from there.
        let _ = tidySetConfigCallback(tdoc, someFunc)
        let configFile = "~/Development/tidy-cocoa/_test_files/sample_01.cfg"
        if tidyLoadConfig(tdoc, configFile) == 0 {
            output("Loaded \(configFile).")
        } else
        {
            output("Could not load \(configFile).")
        }

        _ = tidyParseString( tdoc, "Hello, world")

        // Try out tidyStatus()
        output("tidyStatus is \(tidyStatus(tdoc))")

        // Try out tidyDetectedXhtml -- NEED TO PROCESS A DOCUMENT FIRST.
        output("tidyDetectedXhtml is \(tidyDetectedXhtml(tdoc))")

        tidyErrorSummary(tdoc)
        tidyGeneralInfo(tdoc)

        let myOpts = tidyGetOptionList( tdoc )

        output( "\(tidyOptGetPickList(myOpts[0]))" )

        output("---------------------------------")

        output(errorBuffer.StringValue() ?? "MISSING!")

        output("---------------------------------")
        output( tidySystemLocale() )


        output("---------------------------------")
        output( "\(tidyConfigRecords(forTidyDoc: tdoc))" )


        tidyRelease( tdoc )
    }


}
