//
//  main.swift
//  tidy
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation

//import LibTidy

print("Hello, World!")

//var tidyDoc : TidyDoc
//
//tidyDoc = tidyCreate()


let s = String( cString: tidyLibraryVersion() )
print(s)

//print( tidyLibraryVersion() )
