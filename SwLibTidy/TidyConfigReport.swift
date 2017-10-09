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
 This protocol describes an interface for objects that CLibTidy can use for
 reporting unknown configuration options and proposed values, usually supplied
 by end application users.
*/
public protocol TidyConfigReportProtocol: AnyObject {

    /** The report consists of a dictionary wherein each unrecognized config
        option is a key, and the proposed value is the value. Implementations
        must choose whether or not to discard repeated option values, or to
        mutate repeat option values in order to make the keys unique.
     */
    var report: [ String : String ] { get }

}


/** A default implementation of the `TidyConfigReportProtocol`. */
public class TidyConfigReport: TidyConfigReportProtocol {
    
    public let report: [ String : String ]

    init( withDictionary: Dictionary<String, String> ) {
        report = withDictionary
    }

}


