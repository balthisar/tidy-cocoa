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
       - unknownOption: A string indicating the unknown option name.
       - value: The proposed value of the given option.
       - forTidyDoc: The TidyDocument for which the option was intended.
     - returns:
         Your delegate should return true if it successfully handled the
         unknown option; return false to let Tidy output an error message.
     */
    @objc optional func tidyReports( unknownOption: String, value: String, forTidyDoc: TidyDoc ) -> Swift.Bool

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
       - message: An instance of TidyMessage that Tidy will output.
     - returns:
         Your delegate should return false to indicate that Tidy should not
         further process the message itself.
     */
    @objc optional func tidyReports( message: TidyMessage ) -> Swift.Bool

    /**
     This delegate method is called during the pretty printing process in order
     to provide relational data between source document location and output
     document location.

     - parameters:
       - forDoc: The TidyDoc being pretty printed.
       - line: The line in the source document that corresponds with the current
           output position.
       - col: The column in the source document that corresponds with the
           current output position.
       - destLine: The current position in the output document being written.
     */
    @objc optional func tidyReportsPrettyPrinting( forDoc: TidyDoc, line: UInt, col: UInt, destLine: UInt )
}


