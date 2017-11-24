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

    /** the C format string used to create the main body of the message, in
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

    /** And array of message arguments and argument type information used to
        generate the message. */
    var messageArguments: [TidyMessageArgumentProtocol] { get }

    /** Creates a new instance of this class and sets the values. */
    init( withMessage: TidyMessage )
}


/**
 This protocol describes an interface for accessing the fields of a
 TidyMessageArgument object without having to use the CLibTidy API.
 */
@objc public protocol TidyMessageArgumentProtocol: AnyObject {

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


/** A default implementation of the `TidyMessageProtocol`. */
@objc public class TidyMessageContainer: NSObject, TidyMessageProtocol {

    public var messageCode: UInt
    public var messageKey: String
    public var line: Int
    public var column: Int
    public var level: TidyReportLevel
    public var muted: Swift.Bool
    public var formatDefault: String
    public var format: String
    public var messageDefault: String
    public var message: String
    public var posDefault: String
    public var pos: String
    public var prefixDefault: String
    public var prefix: String
    public var messageOutputDefault: String
    public var messageOutput: String
    public var messageArguments: [TidyMessageArgumentProtocol]

    public required init( withMessage: TidyMessage ) {

        self.messageCode = tidyGetMessageCode( withMessage )
        self.messageKey = tidyGetMessageKey( withMessage )
        self.line = tidyGetMessageLine( withMessage )
        self.column = tidyGetMessageColumn( withMessage )
        self.level = tidyGetMessageLevel( withMessage )
        self.muted = tidyGetMessageIsMuted( withMessage )
        self.formatDefault = tidyGetMessageFormatDefault( withMessage )
        self.format = tidyGetMessageFormat( withMessage )
        self.messageDefault = tidyGetMessageDefault( withMessage )
        self.message = tidyGetMessage( withMessage )
        self.posDefault = tidyGetMessagePosDefault( withMessage )
        self.pos = tidyGetMessagePos( withMessage )
        self.prefixDefault = tidyGetMessagePrefixDefault( withMessage )
        self.prefix = tidyGetMessagePrefix( withMessage )
        self.messageOutputDefault = tidyGetMessageOutputDefault( withMessage )
        self.messageOutput = tidyGetMessageOutput( withMessage )

        self.messageArguments = []

        for arg in tidyGetMessageArguments( forMessage: withMessage ) {
            self.messageArguments.append( TidyMessageArgumentContainer( withArg: arg, fromMessage: withMessage ) )
        }

        super.init()
    }
}


/** A default implementation of the `TidyMessageArgumentProtocol`. */
@objc public class TidyMessageArgumentContainer: NSObject, TidyMessageArgumentProtocol {

    public var type: TidyFormatParameterType
    public var format: String
    public var valueString: String
    public var valueUInt: UInt
    public var valueInt: Int
    public var valueDouble: Double


    public required init( withArg: TidyMessageArgument, fromMessage: TidyMessage ) {

        self.type = tidyGetArgType( fromMessage, withArg )
        self.format = tidyGetArgFormat( fromMessage, withArg )
        self.valueString = ""
        self.valueUInt = 0
        self.valueInt = 0
        self.valueDouble = 0.0

        switch self.type {

        case tidyFormatType_INT:    self.valueInt = tidyGetArgValueInt( fromMessage, withArg )

        case tidyFormatType_UINT:   self.valueUInt = tidyGetArgValueUInt( fromMessage, withArg )

        case tidyFormatType_STRING: self.valueString = tidyGetArgValueString( fromMessage, withArg )

        case tidyFormatType_DOUBLE: self.valueDouble = tidyGetArgValueDouble( fromMessage, withArg )

        default:
            break
        }

        super.init()
    }

}


