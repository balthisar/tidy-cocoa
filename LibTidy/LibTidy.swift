//
//  LibTidy.swift
//  LibTidy
//
//  Created by Jim Derry on 8/10/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//
//  Provide a mostly-pure wrapper to LibTidy using Swift-native types, and by
//  providing arrays instead of forcing the use of iterators.
//
//  Note that GUI apps should simply link to this framework; console apps that
//  want completely static linking should ensure this file is included in the
//  console target and link to the tidy-html5 static library.

import Foundation
import CLibTidy

public func tidyLibraryVersion() -> String {
    let result = String( cString: CLibTidy.tidyLibraryVersion() )
    print("In Function")
    return result
}

