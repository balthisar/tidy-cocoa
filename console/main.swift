//
//  main.swift
//  tidy
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation

/*
    Note that we're not importing anything from LibTidy. The LibTidy.swift
    file is already included by virtue of being included in this build. The
    LibTidy target is *not* used; just this file from its source. Because we've
    included the module.map pointing to tidy.h, it just magically works.
 
    Tidy's library is statically linked.
 
    This means that we can share source with what would otherwise be a dynamic
    framework in order to build a console application without installing any
    frameworks elsewhere.
 */


public func someFunc( tdoc: TidyDoc, option: String, value: String) -> Swift.Bool {
    print("\(option) \(value)")
    return false
}

public func myMessageCallback( _ tmessage: TidyMessage ) -> Bool {
    print("The message callback")
    return true
}

class TidyRunner {

    func printHello() {
        print("Hello, says the printHello function.")
    }

    func RunTidy() {

        // Create a TidyDoc
        let tdoc : TidyDoc = tidyCreate()

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
            print("Loaded \(configFile).")
        } else
        {
            print("Could not load \(configFile).")
        }

        _ = tidyParseString( tdoc, "Hello, world")
        
        // Try out tidyStatus()
        print("tidyStatus is \(tidyStatus(tdoc))")

        // Try out tidyDetectedXhtml -- NEED TO PROCESS A DOCUMENT FIRST.
        print("tidyDetectedXhtml is \(tidyDetectedXhtml(tdoc))")

        tidyErrorSummary(tdoc)
        tidyGeneralInfo(tdoc)
        
        let myOpts = tidyGetOptionList( tdoc )
        
        print( tidyOptGetPickList(myOpts[0]) )
        
        print("---------------------------------")
        
        print(errorBuffer.UTF8String ?? "MISSING!")

        print("---------------------------------")
        print( tidySystemLocale() )


        tidyRelease( tdoc )
    }


}

print("Hello, Tidy Tester!")

let myClass = TidyRunner.init()

myClass.RunTidy()

