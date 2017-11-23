/******************************************************************************

	TidyDelegateProtocol.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
       This protocol defines the delegate methods that can be used with
       SwLibTidy.

 ******************************************************************************/


import Foundation


/**
 This protocol describes an interface for objects that SwLibTidy can use for
 reporting unknown configuration options and proposed values, usually supplied
 by end application users. It is usually used as an array.
 */
@objc public protocol TidyDelegateProtocol: AnyObject {

    @objc optional func tidyReportsUnknownConfigOption( tdoc: TidyDoc, option: String, value: String ) -> Swift.Bool

}


