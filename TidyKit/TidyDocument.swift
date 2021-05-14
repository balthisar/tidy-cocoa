/**
 *  TidyDocument.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *     Defines a default implementation of `TidyDocumentProtocol` as anobject
 *     wrapper around SwLibTidy, and includes compatibility for Objective-C. The
 *     protocol describes an interface for using SwLibTidy as a class in Swift
 *     and Objective-C, abstracting some of the lower-level functions as well
 *     as providing a more Swift-like experience.
 */

import Foundation


//*****************************************************************************
// MARK: - TidyDocument
//*****************************************************************************

/**
 *  A `TidyDocument` is a ready-to-go, reference implementation of the
 *  `TidyDocumentProtocol`. Feel free to extend it, copy and paste it, or do
 *  anything else with it that will make it useful.
 */
@objc public class TidyDocument: NSObject, TidyDocumentProtocol {
   
    /**
     *  The default initializer for classes adopting this protocol.
     */
    public required override init() {
        super.init()
    }

    /**
     *  Intialize with `NSData` to populate `sourceText`.
     */
    public required convenience init( withData: Data ) {
        self.init()
    }

    /**
     *  Initialize with a file to populate `sourceText`.
     */
    public required convenience init( withURL: NSURL ) {
        self.init()
    }

    /**
     *  The text to be tidied.
     */
    public var sourceText: String {
        get {
            self.sourceText
        }
        set(value) {
            self.sourceText = value
        }
    }

    /**
     *  The parsed, tidied text.
     */
    public var tidyText: String {
        get {
            "tidyText"
        }
    }

    /**
     *  The version of HTML that was output.
     */
    public var tidyDetectedHtmlVersion: String {
        get {
            "5.0"
        }
    }

    /**
     *  Indicates whether the output document is or isn't XHTML.
     */
    public var tidyDetectedXhtml: Bool {
        get {
            false
        }
    }
    
    /**
     *  Indicates whether or not the input document was XML. If `TidyXml` tags is
     *  true, or there was an XML declaration in the input document, then this
     *  function will return `true`.
     */
    public var tidyDetectedGenericXml: Bool {
        get{
            false
        }
    }

    /**
     *  Returns more complete information about errors after tidying.
     */
    public var tidyErrorSummary: String {
        get{
            "No errors."
        }
    }


    /**
     *  Returns more general information about markup after tidying.
     */
    public var tidyGeneralInfo: String {
        get{
            "That's MAJOR general info to you."
        }
    }

}
