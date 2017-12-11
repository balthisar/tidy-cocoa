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
      SwLibTidy. As a C library, LibTidy places a lot of emphasis on
      callbacks, but SwLibTidy provides this delegate interface as a more
      Cocoa-like alternative.

 ******************************************************************************/


import Foundation


/**
 This protocol describes an interface for Tidy to report on status and changes
 during certain operations. These methods, if implemented by your delegate,
 can serve as an alternative to closures and/or callbacks that are native to
 Tidy.
 */
@objc public protocol TidyDelegateProtocol: AnyObject {

    /**
     This delegate method is called any time Tidy tries to parse an unknown
     configuration option.

     - parameters:
       - unknownOption: An instance conforming to TidyConfigReportProtocol
           containing the configuration report.
     - returns:
         Your delegate should return true if it successfully handled the
         unknown option; return false to let Tidy output an error message.
     */
    @objc optional func tidyReports( unknownOption: TidyConfigReportProtocol ) -> Swift.Bool

    /**
     This delegate method is called whenever an option value is changed.

     - parameters:
       - optionChanged: The option that was changed.
       - forTidyDoc: The TidyDoc whose option was changed.
     */
    @objc optional func tidyReports( optionChanged: TidyOption, forTidyDoc: TidyDoc )

    /**
     This delegate method is called any time Tidy is about to emit a message
     of any sort to its internal buffer.

     - parameters:
       - message: An instance of TidyMessageProtocol that Tidy will output.
     - returns:
         Your delegate should return false to indicate that Tidy should not
         further process the message itself.
     */
    @objc optional func tidyReports( message: TidyMessageProtocol ) -> Swift.Bool

    /**
     This delegate method is called during the pretty printing process in order
     to provide relational data between source document location and output
     document location.

     - parameters:
       - pprint: An instance of TidyPProgressProtocol containing the progress
           report.
     */
    @objc optional func tidyReports( pprint: TidyPPProgressProtocol )
}


