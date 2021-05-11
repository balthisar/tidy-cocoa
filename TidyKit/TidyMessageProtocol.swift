/**
 *  SwLibTidyMessageProtocol.swift
 *   Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
 *   See https://github.com/htacg/tidy-html5
 *
 *   Copyright © 2017-2021 by HTACG. All rights reserved.
 *   Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 *   this source code per the W3C Software Notice and License:
 *   https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231
 *
 *   Purpose
 *    This protocol and class define and implement a structure suitable for
 *    storing CLibTidy output messages.
 */

import Foundation
import CLibTidy


/**
 This protocol describes an interface for accessing the fields of a TidyMessage
 object without having to use the CLibTidy API.
 */
@objc public protocol SwLibTidyMessageProtocol: AnyObject {

    /** A reference to the TidyDocument from which the message originates. */
    var document: TidyDoc { get }

    /** An integer representing the internal message code. In native LibTidy,
        this would be a meaningful enum, which doesn't carry over into Swift.
        THIS IS NOT A STABLE VALUE. Use messageKey, instead, which is the
        textual representation of the enum label. */
    var messageCode: UInt { get }

    /** A string representing the unique key that identifies a messages type
        within LibTidy. While not guaranteed not to disappear, these do tend
        to remain stable between releases. */
    var messageKey: String { get }

    /** The line number the message refers to, if any. */
    var line: Int { get }

    /** The column number the messages refers to, if any. */
    var column: Int { get }

    /** The TidyReportLevel of the message. */
    var level: TidyReportLevel { get }

    /** Whether or not the user set an option indicating that this message
        should be muted. */
    var muted: Swift.Bool { get }

    /** The C format string used to create the main body of the message, in
        Tidy's default (English) localization. */
    var formatDefault: String { get }

    /** The C format string used to create the main body of the message, in
        Tidy's currently set language. */
    var format: String { get }

    /** The main body of the message, in Tidy's default (English) language. */
    var messageDefault: String { get }

    /** The main body of the message, in Tidy's curently set language. */
    var message: String { get }

    /** The position part of the complete message, if any, in Tidy's default
        (English) localization. */
    var posDefault: String { get }

    /** The position part of the complete message, if any, in Tidy's currently
        set localization. */
    var pos: String { get }

    /** The prefix part of the message in Tidy's default (English) language. */
    var prefixDefault: String { get }

    /** The prefix part of the message in Tidy's currently set language. */
    var prefix: String { get }

    /** The complete message as Tidy would output it in the default language.*/
    var messageOutputDefault: String { get }

    /** The complete message as Tidy would output it in the current language.*/
    var messageOutput: String { get }

    /** An array of message arguments and argument type information used to
        generate the message. */
    var messageArguments: [SwLibTidyMessageArgumentProtocol] { get }

    /** Creates a new instance of this class and sets the values. */
    init( withMessage: TidyMessage )
}


/**
 This protocol describes an interface for accessing the fields of a
 TidyMessageArgument object without having to use the CLibTidy API.
 */
@objc public protocol SwLibTidyMessageArgumentProtocol: AnyObject {

    /** Indicates the data type of the C printf argument. */
    var type: TidyFormatParameterType { get }

    /** Indicates the C printf format specifier for the argument. */
    var format: String { get }

    /** The value of the argument, if it's tidyFormatType_STRING. */
    var valueString: String { get }

    /** The value of the argument, if it's tidyFormatType_UINT. */
    var valueUInt: UInt { get }

    /** The value of the argument, if it's tidyFormatType_INT. */
    var valueInt: Int { get }

    /** The value of the argument, if it's tidyFormatType_DOUBLE. */
    var valueDouble: Double { get }

    /** Creates a new instance of this class populating the fields
        from the given TidyMessage and argument */
    init( withArg: TidyMessageArgument, fromMessage: TidyMessage )
}


/** A default implementation of the `SwLibTidyMessageProtocol`. */
@objc public class SwLibTidyMessage: NSObject, SwLibTidyMessageProtocol {

    @objc public var document: TidyDoc
    @objc public var messageCode: UInt
    @objc public var messageKey: String
    @objc public var line: Int
    @objc public var column: Int
    @objc public var level: TidyReportLevel
    @objc public var muted: Swift.Bool
    @objc public var formatDefault: String
    @objc public var format: String
    @objc public var messageDefault: String
    @objc public var message: String
    @objc public var posDefault: String
    @objc public var pos: String
    @objc public var prefixDefault: String
    @objc public var prefix: String
    @objc public var messageOutputDefault: String
    @objc public var messageOutput: String
    @objc public var messageArguments: [SwLibTidyMessageArgumentProtocol]

    @objc public required init( withMessage: TidyMessage ) {

        self.document = CLibTidy.tidyGetMessageDoc( withMessage )
        self.messageCode = UInt( CLibTidy.tidyGetMessageCode( withMessage ) )
        self.messageKey = String( cString: CLibTidy.tidyGetMessageKey( withMessage ))
        self.line = Int( CLibTidy.tidyGetMessageLine( withMessage) )
        self.column = Int( CLibTidy.tidyGetMessageColumn( withMessage ) )
        self.level = CLibTidy.tidyGetMessageLevel( withMessage )
        self.muted = CLibTidy.tidyGetMessageIsMuted( withMessage ) == yes ? true : false
        self.formatDefault = String( cString: CLibTidy.tidyGetMessageFormatDefault( withMessage ) )
        self.format = String( cString: CLibTidy.tidyGetMessageFormat( withMessage ) )
        self.messageDefault = String( cString: CLibTidy.tidyGetMessageDefault( withMessage ) )
        self.message = String( cString: CLibTidy.tidyGetMessage( withMessage ) )
        self.posDefault = String( cString: CLibTidy.tidyGetMessagePosDefault( withMessage ) )
        self.pos = String( cString: CLibTidy.tidyGetMessagePos( withMessage ) )
        self.prefixDefault = String( cString: CLibTidy.tidyGetMessagePrefixDefault( withMessage ) )
        self.prefix = String( cString: CLibTidy.tidyGetMessagePrefix( withMessage ) )
        self.messageOutputDefault = String( cString: CLibTidy.tidyGetMessageOutputDefault( withMessage ) )
        self.messageOutput = String( cString: CLibTidy.tidyGetMessageOutput( withMessage ) )

        self.messageArguments = []
        var it: TidyIterator? = CLibTidy.tidyGetMessageArguments( withMessage )

        while ( it != nil ) {
            if let arg = CLibTidy.tidyGetNextMessageArgument( withMessage, &it ) {
                self.messageArguments.append( SwLibTidyMessageArgument( withArg: arg, fromMessage: withMessage ) )
            }
        }
    }
}


/** A default implementation of the `SwLibTidyMessageArgumentProtocol`. */
@objc public class SwLibTidyMessageArgument: NSObject, SwLibTidyMessageArgumentProtocol {

    @objc public var type: TidyFormatParameterType
    @objc public var format: String
    @objc public var valueString: String
    @objc public var valueUInt: UInt
    @objc public var valueInt: Int
    @objc public var valueDouble: Double


    @objc public required init( withArg: TidyMessageArgument, fromMessage: TidyMessage ) {

        var ptrArg: TidyMessageArgument? = withArg

        self.type = CLibTidy.tidyGetArgType( fromMessage, &ptrArg )
        self.format = String( cString: CLibTidy.tidyGetArgFormat( fromMessage, &ptrArg ) )
        self.valueString = ""
        self.valueUInt = 0
        self.valueInt = 0
        self.valueDouble = 0.0

        switch self.type {

        case tidyFormatType_INT:    self.valueInt = Int( CLibTidy.tidyGetArgValueInt( fromMessage, &ptrArg ) )

        case tidyFormatType_UINT:   self.valueUInt = UInt( CLibTidy.tidyGetArgValueUInt( fromMessage, &ptrArg ) )

        case tidyFormatType_STRING: self.valueString = String( cString: CLibTidy.tidyGetArgValueString( fromMessage, &ptrArg ) )

        case tidyFormatType_DOUBLE: self.valueDouble = Double( CLibTidy.tidyGetArgValueDouble( fromMessage, &ptrArg ) )

        default: break
        }
    }

}


