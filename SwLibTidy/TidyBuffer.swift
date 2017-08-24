/******************************************************************************

	TidyBuffer.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
       This protocol and class define and implement an abstraction to the
       CLibTidy `TidyBuffer` that is more useful in Swift.
 
 ******************************************************************************/

import Foundation
import CLibTidy


/**
 This protocol describes an interface for objects that CLibTidy can use for
 performing the majority of its input/output operations. Unless using standard 
 I/O or files, Tidy inherently requires the use of C buffers in order to 
 perform its I/O, and objects implementing this protocol satisfy Tidy's
 requirement while also abstracting most of the C pointer handling and unsafe
 types that are involved in such.
 
 Conforming objects are also required to provide accessors and functions that
 enable accessing the raw, stored data.
*/
protocol TidyBufferProtocol: AnyObject {
    
    typealias TidyBufferPtr = UnsafeMutablePointer<CLibTidy.TidyBuffer>
    typealias TidyRawBuffer = UnsafeMutablePointer<byte>
    
    
    /** An accessor to the underlying TidyBuffer type from CLibTidy. */
    var tidyBuffer: TidyBufferPtr { get }
    
    
    /** An accessor to the underlying raw data buffer used by CLibTidy. When
        using non-UTF8 buffers, you will want to convert this data into a
        string or other representation yourself with the correct encoding.
     */
    var rawBuffer: UnsafeMutablePointer<byte> { get }
    
    
    /** Provides an accessor to the underlying raw buffer's data size.*/
    var rawBufferSize: UInt { get }
    
    
    /** Provides the contents of the buffer as a string decoded according to
        the specifed CLibTidy encoding type passed via `usingTidyEncoding:`
        Tidy's buffer may contain representations in other than UTF8 format
        as specified by `output-encoding`. Decoding will be performed by Cocoa,
        and not CLibTidy.
     
    - parameters:
        - usingTidyEncoding: The CLibTidy encoding type. Valid values include
          `ascii`, `latin1`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`,
          `utf16be`, `utf16`, `big5`, and `shiftjis`. These values are not
          case sensitive. `raw` is not supported.
    - returns:
         Returns an optional string with the decoded content.
     */
    func StringValue( usingTidyEncoding: String ) -> String?
    
    
    /** Provides the contents of the buffer as a string decoded according to
        the `output-encoding` setting of the provided TidyDoc.
     
    - parameters:
      - usingTidyDoc: The `output-encoding` setting of the given TidyDoc will
        be used to determine how the buffer is translated into a string. In
        general this should only be used for the document output buffer, as all
        other Tidy output is always UTF8.
    - returns:
        Returns an optional string with the decoded content.
     */
    func StringValue( usingTidyDoc: TidyDoc ) -> String?
    
   
    /** Sets the buffer from a provided string. The buffer's encoding will match
        the `usingTidyEncoding` parameter.
     
    - parameters:
        - fromString: The native string to store in the buffer.
        - usingTidyEncoding: The CLibTidy encoding type. Valid values include
          `ascii`, `latin1`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`,
          `utf16be`, `utf16`, `big5`, and `shiftjis`. These values are not
          case sensitive. `raw` is not supported.
    - returns:
         Returns `true` or `false` indicating success or failure. TODO: throws?
     */
    func setStringValue( fromString: String, usingTidyEncoding: String ) -> Swift.Bool
    

    /** Sets the buffer from a provided string. The buffer's encoding will match
    the `input-encoding` setting of the provided `TidyDoc`.
     
    - parameters:
        - fromString: The native string to store in the buffer.
        - usingTidyDoc: The `input-encoding` setting of the given TidyDoc will
          be used to determine how to translate the string to the buffer's
          internal representation.
    - returns:
         Returns `true` or `false` indicating success or failure. TODO: throws?
     */
    func setStringValue( usingTidyDoc: TidyDoc ) -> Swift.Bool
    
}


public class TidyBuffer: TidyBufferProtocol {
    
    typealias TidyBufferPtr = UnsafeMutablePointer<CLibTidy.TidyBuffer>
    typealias TidyRawBuffer = UnsafeMutablePointer<byte>
//    fileprivate typealias _tidybuff = UnsafeMutablePointer<CLibTidy.TidyBuffer>
    
    var tidyBuffer: TidyBufferPtr

    private let big5encoding: String.Encoding
    private let encAssociations: [ String : String.Encoding ]
    
    /** An accessor to the underlying raw data buffer used by CLibTidy. When
        using non-UTF8 buffers, you will want to convert this data into a
        string or other representation yourself with the correct encoding.
     */
    var rawBuffer: UnsafeMutablePointer<byte> {
        return tidyBuffer.pointee.bp
    }
    
    /** Provides an accessor to the underlying raw buffer's data size.*/
    var rawBufferSize: UInt {
        return UInt(tidyBuffer.pointee.size)
    }
    
    /** Provides the contents of the buffer as a string assuming internal UTF8
        representation. All of Tidy's output is UTF8 *except* for Tidy's
        document output buffer, which will contain data encoded according to
        Tidy's `output-encoding`.
     */
    var UTF8String: String? {
        guard rawBufferSize > 0 else { return nil }
        
        let theData = Data( bytes: rawBuffer, count: Int(rawBufferSize) )

        return Swift.String( data: theData, encoding: .utf8 )
    }
    
    /** Initializes the buffer and makes it ready for use. */
    init() {
        
        tidyBuffer = TidyBufferPtr.allocate(capacity: MemoryLayout<TidyBufferPtr>.size)
        tidyBufInit( tidyBuffer )

        let cfEnc = CFStringEncodings.big5
        let nsEnc = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEnc.rawValue))
        big5encoding = Swift.String.Encoding(rawValue: nsEnc)

        encAssociations = [
            "ascii"    : Swift.String.Encoding.ascii,
            "latin1"   : Swift.String.Encoding.isoLatin1,
            "utf8"     : Swift.String.Encoding.utf8,
            "iso2022"  : Swift.String.Encoding.iso2022JP,
            "mac"      : Swift.String.Encoding.macOSRoman,
            "win1252"  : Swift.String.Encoding.windowsCP1252,
            "utf16le"  : Swift.String.Encoding.utf16LittleEndian,
            "utf16be"  : Swift.String.Encoding.utf16BigEndian,
            "utf16"    : Swift.String.Encoding.utf16,
            "big5"     : big5encoding,
            "shiftjis" : Swift.String.Encoding.shiftJIS
        ]

    }
    
    deinit {
        tidyBufFree( tidyBuffer )
        free( tidyBuffer )
    }
    
    
    func StringValue( usingTidyEncoding: String = "utf8" ) -> String? {
        
        guard
            rawBufferSize > 0,
            let encoding = encAssociations[ usingTidyEncoding ]
        else { return nil }
        
        let theData = Data( bytes: rawBuffer, count: Int(rawBufferSize) )
        
        return Swift.String( data: theData, encoding: encoding )
    }
    
    func StringValue( usingTidyDoc: TidyDoc ) -> String? {
        return nil
    }

    func setStringValue( fromString: String, usingTidyEncoding: String ) -> Swift.Bool {
        return true
    }
    

    func setStringValue( usingTidyDoc: TidyDoc ) -> Swift.Bool {
        return true
    }
    


}


