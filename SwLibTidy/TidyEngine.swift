/******************************************************************************

    TidyEngine.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      Provides an object wrapper around SwLibTidy, and includes compatibility
      for Objective-C.
 
 ******************************************************************************/

import Foundation
//import CLibTidy // Not found when called from bridging -Swift.h header!


@objc public class TidyEngine: NSObject {

    private var doc = SwLibTidy.tidyCreate()

//    public init?() {
//    }
//
    deinit {
        if let doc = doc {
            SwLibTidy.tidyRelease( doc )
        }
    }

    // Can't return optional to objc.
    @objc public func getOptionId( forName: String ) -> MyTidyOptionId {

        return SwLibTidy.tidyOptGetIdForName( forName )!
    }

    @objc public func getHello() -> String {
        return "Hello, Jim"
    }

    
}




