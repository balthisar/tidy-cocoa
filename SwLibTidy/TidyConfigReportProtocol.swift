/******************************************************************************

	TidyConfigReportProtocol.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      This protocol and class define and implement an object for the
      collection of configuration report data as a supplement/substitute
      for using the ConfigCallback.

 ******************************************************************************/

import Foundation
import CLibTidy


/**
 This protocol describes an interface for objects that SwLibTidy can use for
 reporting unknown configuration options and proposed values, usually supplied
 by end application users. It is usually used as an array.
*/
@objc public protocol TidyConfigReportProtocol: AnyObject {

    /** The Tidy document from which the report originated. */
    var document: TidyDoc { get }

    /** The unrecognized configuration option. */
    var option: String { get }

    /** The proposed value for the unrecognized configuration option. */
    var value: String { get }

    /** Create an instance with this value for the given option. */
    init(withValue: String, forOption: String, ofDocument: TidyDoc)

}


/** A default implementation of the `TidyConfigReportProtocol`. */
@objc public class TidyConfigReport: NSObject, TidyConfigReportProtocol {
    
    public var document: TidyDoc
    public var option: String = ""
    public var value: String = ""

    public required init(withValue: String, forOption: String, ofDocument: TidyDoc) {

        document = ofDocument
        option = forOption
        value = withValue
        super.init()
    }
}

