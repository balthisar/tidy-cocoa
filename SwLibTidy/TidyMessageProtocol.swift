/******************************************************************************

 TidyMessageProtocol.swift
 Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 See https://github.com/htacg/tidy-html5

 Copyright © 2107 by HTACG. All rights reserved.
 Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 this source code per the W3C Software Notice and License:
 https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

 Purpose
 This protocol and class define and implement a structure suitable for
 storing CLibTidy output messages.

 ******************************************************************************/

import Foundation
import CLibTidy


/**
 This protocol describes an interface for accessing the fields of a TidyMessage
 object without having to use the CLibTidy API.
 */
@objc public protocol TidyMessageProtocol: AnyObject {

    var messageCode: UInt { get }

    var messageKey: String { get }

    var line: UInt { get }
    var column: UInt { get }
    var level: TidyReportLevel { get }
    var formatDefault: String { get }
    var format: String { get }
    var messageDefault: String { get }
    var message: String { get }
    var posDefault: String { get }
    var pos: String { get }
    var prefixDefault: String { get }
    var prefix: String { get }
    var messageOutputDefault: String { get }
    var messageOutput: String { get }
    var messageArguments: [String] { get }
    
/*
    - tidyGetArgType()
    - tidyGetArgFormat()
    - tidyGetArgValueString()
    - tidyGetArgValueUInt()
    - tidyGetArgValueInt()
    - tidyGetArgValueDouble()
*/

    init( withMessage: TidyMessage )


}


/** A default implementation of the `TidyMessageProtocol`. */
@objc public class TidyMessageContainer: NSObject, TidyMessageProtocol {

    public required init( withMessage: TidyMessage ) {
        super.init()
    }

}



