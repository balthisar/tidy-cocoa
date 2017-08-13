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

class TidyRunner {

    func printHello() {
        print("Hello")
    }

    func RunTidy() {
        print( tidyLibraryVersion() )
        print( tidyReleaseDate() )

        // Create a TidyDoc
        let myTidy : TidyDoc = tidyCreate()

        // Store a reference to self here, so that we can fetch it later.
        tidySetAppData(myTidy, self)

        // Ensure that the stored reference survives the round trip.
        if let myInstance = tidyGetAppData(myTidy) as? TidyRunner {
            myInstance.printHello()
        }

        // Try out tidyStatus()
        print("tidyStatus is \(tidyStatus(myTidy))")

        // Try out tidyDetectedXhtml -- NEED TO PROCESS A DOCUMENT FIRST.
//        print("tidyDetectedXhtml is \(tidyDetectedXhtml(myTidy))")

        tidyErrorSummary(myTidy)
        tidyGeneralInfo(myTidy)
        

        tidyRelease( myTidy )
    }


}

print("Hello, World!")

let myClass = TidyRunner.init()

myClass.RunTidy()

