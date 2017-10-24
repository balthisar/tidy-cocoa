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
 by end application users.
*/
public protocol TidyConfigReportProtocol: AnyObject {

    /**
     The report consists of an array of dictionaries with the key `config`
     containing the unrecognized config value, and the key `value` containing
     the proposed value.
     */
    var report: [Dictionary<String, String>] { get }

    /**
     Add a configuration and value to the report.
     */
    func add( config: String, value: String )

}


/** A default implementation of the `TidyConfigReportProtocol`. */
@objc public class TidyConfigReport: NSObject, TidyConfigReportProtocol {
    
    public var report: [Dictionary<String, String>] = []

    public func add( config: String, value: String ) {

        let newDict = [ "config" : config, "value" : value ]

        report.append( newDict )
    }

}


