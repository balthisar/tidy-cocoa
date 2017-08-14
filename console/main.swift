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


public func someFunc( tdoc: TidyDoc, s1: String, s2: String) -> Swift.Bool {
    return true
}

class TidyRunner {

    func printHello() {
        print("Hello")
    }

    func RunTidy() {

        print( tidyLibraryVersion() )
        print( tidyReleaseDate() )

        // Create a TidyDoc
        let tdoc : TidyDoc = tidyCreate()

        // Store a reference to self here, so that we can fetch it later.
        tidySetAppData(tdoc, self)

        // Ensure that the stored reference survives the round trip.
        if let myInstance = tidyGetAppData(tdoc) as? TidyRunner {
            myInstance.printHello()
        }

        // Let's load a configuration file. Note, eventually copy these to
        // the bundle and load them from there.
        let _ = tidySetConfigCallback(tdoc, someFunc)
        let configFile = "~/Development/tidy-cocoa/_test_files/sample_01.cfg"
        if tidyLoadConfig(tdoc, configFile) == 0 {
            print("Loaded \(configFile).")
        } else
        {
            print("Could not load \(configFile).")
        }



        // Try out tidyStatus()
        print("tidyStatus is \(tidyStatus(tdoc))")

        // Try out tidyDetectedXhtml -- NEED TO PROCESS A DOCUMENT FIRST.
//        print("tidyDetectedXhtml is \(tidyDetectedXhtml(myTidy))")

        tidyErrorSummary(tdoc)
        tidyGeneralInfo(tdoc)
        

        tidyRelease( tdoc )
    }


}

print("Hello, World!")

let myClass = TidyRunner.init()

myClass.RunTidy()

