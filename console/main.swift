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

print("Hello, World!")

//var tidyDoc : TidyDoc
//
//tidyDoc = tidyCreate()


//let s = String( cString: tidyLibraryVersion() )
//print(s)

print( tidyLibraryVersion() )
