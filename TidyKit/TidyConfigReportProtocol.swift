/**
 *  TidyConfigReportProtocol.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *    This protocol and class define and implement an object for the
 *    collection of configuration report data as a supplement/substitute
 *    for using the ConfigCallback.
 */

import Foundation


/**
 This protocol describes an interface for objects that SwLibTidy can use for
 reporting unknown configuration options and proposed values, usually supplied
 by end application users. It is usually used as an array.
*/
@objc public protocol SwLibTidyConfigReportProtocol: AnyObject {

    /** The Tidy document from which the report originated. */
    var document: TidyDoc { get }

    /** The unrecognized configuration option. */
    var option: String { get }

    /** The proposed value for the unrecognized configuration option. */
    var value: String { get }

    /** Create an instance with this value for the given option. */
    init(withValue: String, forOption: String, ofDocument: TidyDoc)

}


/** A default implementation of the `SwLibTidyConfigReportProtocol`. */
@objc public class SwLibTidyConfigReport: NSObject, SwLibTidyConfigReportProtocol {
    
    @objc public var document: TidyDoc
    @objc public var option: String = ""
    @objc public var value: String = ""

    @objc public required init(withValue: String, forOption: String, ofDocument: TidyDoc) {

        document = ofDocument
        option = forOption
        value = withValue
    }
}

