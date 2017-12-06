/******************************************************************************

    TidyDocument.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      Defines a protocol and default implementation for an object wrapper
      around SwLibTidy, and includes compatibility for Objective-C.
 
 ******************************************************************************/

import Foundation


/**
 This protocol describes an interface for using SwLibTidy as a class in Swift
 and Objective-C, abstracting some of the lower-level functions as well as
 providing a more Swift-like experience.

 */
@objc public protocol TidyDocumentProtocol: AnyObject {

}

@objc public class TidyDocument: NSObject {

    private var doc = tidyCreate()

//    public init?() {
//    }
//
    deinit {
        if let doc = doc {
            tidyRelease( doc )
        }
    }

    // Can't return optional to objc.
    @objc public func getOptionId( forName: String ) -> TidyOptionId {

        return tidyOptGetIdForName( forName )!
    }

    @objc public func getHello() -> String {
        return "Hello, Jim"
    }

    
}




