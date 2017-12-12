/******************************************************************************

    TidyDocument.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      Defines a protocol and default implementation for an object wrapper
      around SwLibTidy, and includes compatibility for Objective-C. The
      protocol describes an interface for using SwLibTidy as a class in Swift
      and Objective-C, abstracting some of the lower-level functions as well
      as providing a more Swift-like experience.

    General
      CLibTidy's TidyDoc is re-described as a protocol, and many of the
      functions have been made into type properties and methods, and instance
      properties and methods. Additionally, where methods are use, Swift and
      Cocoa conventions and types are used instead of C/Tidy types.

    Unimplemented Functions
      Functions with built-in Cocoa equivalents have not been included, e.g.,
      `tidyFileExists()`.

      Also abstracted away is all notion of STDIN and STDOUT. All non-URL
      I/O is string-based, and anything that would have been written to an
      error file, stderr, or stdout by CLibTidy is available as a string. Use
      Cocoa for any type of output that you may need.

 ******************************************************************************/

import Foundation


/**
 Describe CLibTidy's `TidyDoc` as a protocol.
 */
@objc public protocol TidyDocumentProtocol: AnyObject {

// MARK: Host Application Data

    /**
     Allows the host application to store a reference to an object instance.
     This can be useful for callbacks, such as saving a reference to `self`.
     Because callbacks in Swift can only call back to a global function (not
     an instance method), it will be useful to know (in your callback) which
     instance of your class generated the callback.
    */
    var appData: AnyObject? { get set }


// MARK: CLibTidy Version Information


    /** Get the release date for the current library. */
    static var tidyReleaseDate: String { get }

    /** Get the version number for the current library. */
    static var tidyLibraryVersion: String { get }

    /** Get the platform name from the current library. */
    static var tidyPlatform: String { get }


// MARK: - Diagnostics and Repair Status

    /**
     Get status of the document, which is the highest of `2`, indicating that
     errors were present in the docment, `1`, indicating warnings, or `0`,
     in the case of everything being okay.
     */
    var tidyStatus: Int { get }

    /**
     Gets the version of HTML that was output, as an integer, times 100. For
     example, HTML5 will return 500; HTML4.0.1 will return 401.
     */
    var tidyDetectedHtmlVersion: Int { get }



    /** Indicates whether the output document is or isn't XHTML. */
    var tidyDetectedXhtml: Bool { get }


    /**
     Indicates whether or not the input document was XML. If `TidyXml` tags is
     true, or there was an XML declaration in the input document, then this
     function will return `true`.
     */
    var tidyDetectedGenericXml: Bool { get }


    /**
     Indicates the number of `TidyError` messages that were generated. For any
     value greater than `0`, output is suppressed unless `TidyForceOutput` is
     set.
     */
    var tidyErrorCount: UInt { get }


    /** Indicates the number of `TidyWarning` messages that were generated. */
    var tidyWarningCount: UInt { get }


    /** Indicates the number of `TidyAccess` messages that were generated.
     TODO: do we really need these? Can get tidymessages.map { warning } .count
     */
    var tidyAccessWarningCount: UInt { get }


    /** Indicates the number of configuration error messages.
     TODO: do we really need this? Can get configerrors.count instead.
     */
    var tidyConfigErrorCount: UInt { get }


    /** Returns more complete information about errors after tidying. */
    var tidyErrorSummary: String { get }


    /** Returns more general information about markup after tidying. */
    var tidyGeneralInfo: String { get }


// MARK: - File Operations


    /**
     Load an ASCII Tidy configuration file and set the configuration per its
     contents.

     - parameters:
       - configFile: The complete path to the file to load.
     - returns:
         Returns `0` upon success, or any other value if there was an error.
     */
    func tidyLoad( configFile: String ) -> Int


    /**
     Load a Tidy configuration file with the specified character encoding, and
     set the configuration per its contents.

     - parameters:
       - configFile: The complete path to the file to load.
       - encoding: The encoding to use. See struct `_enc2iana` for valid values.
     - returns:
         Returns `0` upon success, or any other value if there was an error.
     */
    func tidyLoad( configFile: String, encoding: String ) -> Int


// MARK: - Character Encoding


    /**
     Set the input encoding for parsing markup.  Valid values include `ascii`,
     `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
     `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.

     - parameters:
       - inCharEncoding: The encoding name as described above.
     - returns:
         Returns `0` upon success, or a system standard error number `EINVAL`.
     */
    func tidySet( inCharEncoding: String ) -> Int


    /**
     Set the output encoding for writing markup.  Valid values include `ascii`,
     `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
     `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.

     - Note: Changing this value _after_ processing a document will _not_ change
     the results present in any buffers.

     - parameters:
       - outCharEncoding: The encoding name as described above.
     - returns:
         Returns `0` upon success, or a system standard error number `EINVAL`.
     */
    func tidySet( outCharEncoding: String ) -> Int


// MARK: Configuration Callback Functions


    /**
     This typealias represents the required signature for your provided callback
     function should you wish to register one with `tidySetConfigCallback()`. Your
     callback function will be provided with the following parameters.

     - Note: This signature varies from LibTidy's signature in order to provide
     a simple class-based record rather than a list of parameters.

     - parameters:
     - report: An instance of a class conforming toTidyConfigReportProtocol,
     which contains the report data.
     - returns:
     Your callback function will return `true` if it handles the provided
     option, or `false` if it does not. In the latter case, Tidy will issue an
     error indicating the unknown configuration option.
     */
    typealias TidyConfigCallback = ( _ report: TidyConfigReportProtocol ) -> Bool


    /**
     Applications using TidyLib may want to augment command-line and configuration
     file options. Setting this callback allows a LibTidy application developer to
     examine command-line and configuration file options after LibTidy has examined
     them and failed to recognize them.

     # See also:
     - `tidyConfigRecords(forTidyDoc:)`
     - `<TidyDelegateProtocol>tidyReports(unknownOption:)`

     - parameters:
     - tdoc: The document to apply the callback to.
     - swiftCallback: The name of a function of type `TidyConfigCallback` to
     serve as your callback.
     - returns:
     Returns `true` upon success.
     */
    func tidySetConfigCallback( _ tdoc: TidyDoc, _ swiftCallback: @escaping TidyConfigCallback ) -> Bool


    /**
     This typealias represents the required signature for your provided callback
     function should you wish to register one with tidySetConfigChangeCallback().
     Your callback function will be provided with the following parameters.

     - parameters:
     - tdoc: The document instance for which the callback was invoked.
     - option: The option that will be changed.
     */
    typealias TidyConfigChangeCallback = ( _ tdoc: TidyDoc, _ option: TidyOption ) -> Void


    /**
     Applications using TidyLib may want to be informed when changes to options
     are made. Temporary changes made internally by Tidy are not reported, but
     permanent changes made by Tidy (such as indent-spaces or output-encoding)
     will be reported.

     # See also:
     - `<TidyDelegateProtocol>tidyReports(optionChanged:forTidyDoc:)`

     - parameters:
     - tdoc: The document to apply the callback to.
     - swiftCallback: The name of a function of type TidyConfigChangeCallback() to
     serve as your callback.
     - returns:
     Returns true upon success setting the callback.
     */
    func tidySetConfigChangeCallback( _ tdoc: TidyDoc, _ swiftCallback: @escaping TidyConfigChangeCallback ) -> Swift.Bool


// MARK: Option ID Discovery


    /**
     Get ID of given Option

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     The `TidyOptionId` of the given option.
     */
    func tidyOptGetId( _ opt: TidyOption ) -> TidyOptionId


    /**
     Returns the `TidyOptionId` (C enum value) by providing the name of a Tidy
     configuration option.

     - parameters:
     - optnam: The name of the option ID to retrieve.
     - returns:
     The `TidyOptionId` of the given `optname`.
     */
    func tidyOptGetIdForName( _ optnam: String) -> TidyOptionId


// MARK: Getting Instances of Tidy Options


    /**
     Returns an array of `TidyOption` tokens containing each Tidy option, which are
     an opaque type that can be interrogated with other LibTidy functions.

     - Note: This function will return *not* internal-only option types designated
     `TidyInternalCategory`; you should *never* use these anyway.

     - Note: This Swift array replaces the CLibTidy functions `tidyGetOptionList()`
     and `TidyGetNextOption()`, as it is much more natural to deal with Swift
     array types when using Swift.

     - parameters:
     - tdoc: The tidy document for which to retrieve options.
     - returns:
     Returns an array of `TidyOption` opaque tokens.
     */
    func tidyGetOptionList( _ tdoc: TidyDoc ) -> [String] // [TidyOption]


    /**
     Retrieves an instance of `TidyOption` given a valid `TidyOptionId`.

     - parameters:
     - tdoc: The document for which you are retrieving the option.
     - optId: The `TidyOptionId` to retrieve.
     - returns:
     An instance of `TidyOption` matching the provided `TidyOptionId`.
     */
    func tidyGetOption( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> TidyOption?


    /**
     Returns an instance of `TidyOption` by providing the name of a Tidy
     configuration option.

     - parameters:
     - tdoc: The document for which you are retrieving the option.
     - optnam: The name of the Tidy configuration option.
     - returns:
     The `TidyOption` of the given `optname`.
     */
    func tidyGetOptionByName( _ tdoc: TidyDoc, _ optnam: String ) -> TidyOption?


// MARK: Information About Options


    /**
     Get name of given option

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     The name of the given option.
     */
    func tidyOptGetName( _ opt: TidyOption ) -> String


    /**
     Get datatype of given option

     - parameters:
     - opt: An instance of a TidyOption to query.
     - returns:
     The `TidyOptionType` of the given option.
     */
    func tidyOptGetType( _ opt: TidyOption ) -> TidyOptionType


    /**
     Indicates whether or not an option is a list of values

     - parameters:
     - opt: An instance of a TidyOption to query.
     - returns:
     Returns true or false indicating whether or not the value is a list.
     */
    func tidyOptionIsList( _ opt: TidyOption ) -> Swift.Bool


    /**
     Get category of given option

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     The `TidyConfigCategory` of the specified option.
     */
    func tidyOptGetCategory( _ opt: TidyOption ) -> TidyConfigCategory


    /**
     Get default value of given option as a string

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     A string indicating the default value of the specified option.
     */
    func tidyOptGetDefault( _ opt: TidyOption ) -> String


    /**
     Get default value of given option as an unsigned integer

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     An unsigned integer indicating the default value of the specified option.
     */
    func tidyOptGetDefaultInt( _ opt: TidyOption ) -> UInt


    /**
     Get default value of given option as a Boolean value

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     A boolean indicating the default value of the specified option.
     */
    func tidyOptGetDefaultBool( _ opt: TidyOption ) -> Swift.Bool


    /**
     Returns on array of strings indicating the available picklist values for the
     given `TidyOption`.

     - Note: This Swift array replaces the CLibTidy functions `tidyOptGetPickList()`
     and `tidyOptGetNextPick()`, as it is much more natural to deal with Swift
     array types when using Swift.

     - parameters:
     - opt: An instance of a `TidyOption` to query.
     - returns:
     An array of strings with the picklist values, if any.
     */
    func tidyOptGetPickList( _ opt: TidyOption ) -> [String]


    // MARK: Option Value Functions


    /**
     Get the current value of the `TidyOptionId` for the given document.

     - Note: The `optId` *must* have a `TidyOptionType` of `TidyString`.

     - parameters:
     - tdoc: The tidy document whose option value you wish to check.
     - optId: The option ID whose value you wish to check.
     - returns:
     The string value of the given optId.
     */
    func tidyOptGetValue( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String


    /**
     Set the option value as a string.

     - Note: The optId *must* have a `TidyOptionType` of `TidyString`.

     - parameters
     - tdoc: The tidy document for which to set the value.
     - optId: The `TidyOptionId` of the value to set.
     - val: The string value to set.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptSetValue( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: String ) -> Swift.Bool


    /**
     Set named option value as a string, regardless of the `TidyOptionType`.

     - Note: This is good setter if you are unsure of the type.

     - parameters:
     - tdoc: The tidy document for which to set the value.
     - optnam: The name of the option to set; this is the string value from the
     UI, e.g., `error-file`.
     - val: The value to set, as a string.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptParseValue( _ tdoc: TidyDoc, _ optnam: String, _ val: String )


    /**
     Get current option value as an integer.

     - Note: This function returns an integer value, which in C is compatible with
     every C enum. C enums don't come across well in Swift, but it's still very
     important that they be used versus any raw integer value. This protects
     Swift code from C enum value changes. In Swift, the C enums' integer
     values should be used as such: TidySortAttrNone.rawValue

     - parameters:
     - tdoc: The tidy document for which to get the value.
     - optId: The option ID to get.
     - returns:
     Returns the integer value of the specified option.
     */
    func tidyOptGetInt( _ tdoc: TidyDoc, _ optId: TidyOptionId )


    /**
     Set option value as an integer.

     - Note: This function accepts an integer value, which in C is compatible with
     every C enum. C enums don't come across well in Swift, but it's still very
     important that they be used versus any raw integer value. This protects
     Swift code from C enum value changes. In Swift, the C enums' integer
     values should be used as such: TidySortAttrNone.rawValue

     - parameters
     - tdoc: The tidy document for which to set the value.
     - optId: The option ID to set.
     - val: The value to set.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptSetInt( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: UInt32 ) -> Swift.Bool


    /**
     Get current option value as a Boolean.

     - parameters:
     - tdoc: The tidy document for which to get the value.
     - optId: The option ID to get.
     - returns:
     Returns a bool indicating the value.
     */
    func tidyOptGetBool( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> Swift.Bool


    /**
     Set option value as a Boolean.

     - parameters:
     - tdoc: The tidy document for which to set the value.
     - optId: The option ID to set.
     - val: The value to set.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptSetBool( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: Swift.Bool ) -> Swift.Bool


    /**
     Reset option to default value by ID.

     - parameters:
     - tdoc: The tidy document for which to reset the value.
     - opt: The option ID to reset.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptResetToDefault( _ tdoc: TidyDoc, _ opt: TidyOptionId ) -> Swift.Bool


    /**
     Reset all options to their default values.

     - parameters:
     - tdoc: The tidy document for which to reset all values.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptResetAllToDefault( _ tdoc: TidyDoc ) -> Swift.Bool


    /**
     Take a snapshot of current config settings. These settings are stored within
     the tidy document. Note, however, that snapshots do not reliably survive the
     the `tidyParseXXX()` process, as Tidy uses the snapshot mechanism in order to
     store the current configuration right at the beginning of the parsing process.

     - parameters:
     - tdoc: The tidy document for which to take a snapshot.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool


    /**
     Apply a snapshot of config settings to a document.

     - parameters:
     - tdoc: The tidy document for which to apply a snapshot.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptResetToSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool


    /**
     Any settings different than default?

     - parameters:
     - tdoc: The tidy document to check.
     - returns:
     Returns a bool indicating whether or not a difference exists.
     */
    func tidyOptDiffThanDefault( _ tdoc: TidyDoc ) -> Swift.Bool


    /**
     Any settings different than snapshot?

     - parameters:
     - tdoc: The tidy document to check.
     - returns:
     Returns a bool indicating whether or not a difference exists.
     */
    func tidyOptDiffThanSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool


    /**
     Copy current configuration settings from one document to another. Note that
     the destination document's existing settings will be stored as that document's
     snapshot prior to having its option values overwritten by the source
     document's settings.

     - parameters:
     - tdocTo: The destination tidy document.
     - tdocFrom: The source tidy document.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptCopyConfig( _ tdocTo: TidyDoc, _ tdocFrom: TidyDoc ) -> Swift.Bool


    /**
     Get character encoding name. Used with `TidyCharEncoding`,
     `TidyOutCharEncoding`, and `TidyInCharEncoding`.

     - parameters:
     - tdoc: The tidy document to query.
     - optId: The option ID whose value to check.
     - returns:
     The encoding name as a string for the specified option.
     */
    func tidyOptGetEncName( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String


    /**
     Get the current pick list value for the option ID, which can be useful for
     enum types.

     - parameters:
     - tdoc: The tidy document to query.
     - optId: The option ID whose value to check.
     - returns:
     Returns a string indicating the current value of the given option.
     */
    func tidyOptGetCurrPick( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String


    /**
     Returns on array of strings, where each string indicates a user-declared tag,
     including autonomous custom tags detected when `TidyUseCustomTags` is not set
     to `no`.

     - Note: This Swift array replaces the CLibTidy `tidyOptGetDeclTagList()`
     and `tidyOptGetNextDeclTag()` functions, as it is much more natural to
     deal with Swift array types when using Swift.

     - parameters
     - tdoc: The `TidyDoc` for which to get user-declared tags.
     - optId: The option ID matching the type of tag to retrieve. This
     limits the scope of the tags to one of `TidyInlineTags`, `TidyBlockTags`,
     `TidyEmptyTags`, `TidyPreTags`. Note that autonomous custom tags (if
     used) are added to one of these option types, depending on the value of
     `TidyUseCustomTags`.
     - returns:
     An array of strings with the tag names, if any.
     */
    func tidyOptGetDeclTagList( _ tdoc: TidyDoc, forOptionId optId: TidyOptionId ) -> [String]


    /**
     Returns on array of strings, where each string indicates a prioritized
     attribute.

     - Note: This Swift array replaces the CLibTidy `tidyOptGetPriorityAttrList()`
     and `tidyOptGetNextPriorityAttr()` functions, as it is much more natural
     to deal with Swift array types when using Swift.

     - parameters
     - tdoc: The `TidyDoc` for which to get prioritized attributes.
     - returns:
     An array of strings with the attribute names, if any.
     */
    func tidyOptGetPriorityAttrList( _ tdoc: TidyDoc ) -> [String]


    /**
     Returns on array of strings, where each string indicates a type name for a
     muted message.

     - Note: This Swift array replaces the CLibTidy `tidyOptGetMutedMessageList()`
     and `tidyOptGetNextMutedMessage()` functions, as it is much more natural
     to deal with Swift array types when using Swift.

     - parameters
     - tdoc: The `TidyDoc` for which to get user-declared tags.
     - returns:
     An array of strings with the muted message names, if any.
     */
    func tidyOptGetMutedMessageList( _ tdoc: TidyDoc ) -> [String]


    // MARK: Option Documentation


    /**
     Get the description of the specified option.

     - parameters:
     - tdoc: The tidy document to query.
     - opt: The option ID of the option.
     - returns:
     Returns a string containing a description of the given option.
     */
    func tidyOptGetDoc( _ tdoc: TidyDoc, _ opt: TidyOption ) -> String


    /**
     Returns on array of `TidyOption`, where array element consists of options
     related to the given option ID.

     - Note: This Swift array replaces the CLibTidy `tidyOptGetDocLinksList()`
     and `tidyOptGetNextDocLinks()` functions, as it is much more natural to
     deal with Swift array types when using Swift.

     - parameters
     - tdoc: The `TidyDoc` for which to get user-declared tags.
     - optId: The option ID for which to retrieve related options.
     - returns:
     An array of `TidyOption` instances, if any.
     */
    func tidyOptGetDocLinksList( _ tdoc: TidyDoc, _ opt: TidyOption ) -> [String] //[TidyOption]


    /***************************************************************************//**
     ** Tidy provides flexible I/O. By default, Tidy will define, create and use
     ** instances of input and output handlers for standard C buffered I/O (i.e.,
     ** `FILE* stdin`, `FILE* stdout`, and `FILE* stderr` for content input,
     ** content output and diagnostic output, respectively. A `FILE* cfgFile`
     ** input handler will be used for config files. Command line options will
     ** just be set directly.
     ******************************************************************************/
    // MARK: - I/O and Messages


    /**
     This typealias provides a type for dealing with non-standard input and output
     streams in Swift. In general you can set CLibTidy's input streams and then
     forget them, however if you wish to contribute additional I/O with these
     non-standard streams, you will have to do it with a C-type API.
     */
    typealias CFilePointer = UnsafeMutablePointer<FILE>


    // MARK: - Emacs-compatible reporting support


    /**
     Set the file path to use for reports when `TidyEmacs` is being used. This
     function provides a proper interface for using the hidden, internal-only
     `TidyEmacsFile` configuration option.

     - Note: This is useful if you work with Emacs and prefer Tidy's report
     output to be in a form that is easy for Emacs to parse

     - parameters:
     - tdoc: The tidy document for which you are setting the `filePath`.
     - filePath: The path of the document that should be reported.
     */
    func tidySetEmacsFile( _ tdoc: TidyDoc, _ filePath: String )

    /**
     Get the file path to use for reports when `TidyEmacs` is being used. This
     function provides a proper interface for using the hidden, internal-only
     `TidyEmacsFile` configuration option.

     - parameters:
     - tdoc: The tidy document for which you want to fetch the file path.
     - returns:
     Returns a string indicating the file path.
     */
    func tidyGetEmacsFile( _ tdoc: TidyDoc ) -> String


// MARK: Error Sink


    /**
     Set error sink to named file.

     - parameters:
     - tdoc: The document to set.
     - errfilname: The file path to send output.
     - returns:
     Returns a file handle.
     */
    @discardableResult func tidySetErrorFile( _ tdoc: TidyDoc, _ errfilnam: String ) -> CFilePointer?


    /**
     Set error sink to given buffer.

     - parameters:
     - tdoc: The document to set.
     - errbuf: An instance of TidyBuffer to provide output.
     - returns:
     Returns 0 upon success or a standard error number.
     */
    func tidySetErrorBuffer( _ tdoc: TidyDoc, errbuf: TidyBufferProtocol ) -> Int


    /***************************************************************************//**
     A sophisticated and extensible callback to filter or collect messages
     reported by Tidy. Note that unlike the older filters, this callback exposes
     *all* output that LibTidy emits (excluding the console application, which
     is a client of LibTidy).
     ******************************************************************************/
    // MARK: Error and Message Callbacks - TidyMessageCallback


    /**
     This typealias represents the required signature for your provided callback
     function should you wish to register one with tidySetMessageCallback().
     Your callback function will be provided with the following parameters.

     - parameters:
     - record: An instance conforming to TidyMessageProtocol.
     - returns: Your callback function will return `true` if Tidy should include the
     report in its own output sink, or `false` if Tidy should suppress it.
     */
    typealias TidyMessageCallback = ( _ record: TidyMessageProtocol ) -> Swift.Bool


    /**
     This function informs Tidy to use the specified callback to send reports.

     # See also:
     - `tidyMessageRecords(forTidyDoc:)`
     - `<TidyDelegateProtocol>tidyReports(message:)`

     - parameters:
     - tdoc: The tidy document for which the callback applies.
     - filtCallback: A pointer to your callback function of type
     `TidyMessageCallback`.
     - returns:
     A boolean indicating success or failure setting the callback.
     */
    func tidySetMessageCallback( _ tdoc: TidyDoc, _ swiftCallback: @escaping TidyMessageCallback ) -> Swift.Bool


    /***************************************************************************//**
     ** LibTidy applications can somewhat track the progress of the tidying process
     ** by using this provided callback. It relates where something in the source
     ** document ended up in the output.
     ******************************************************************************/
    // MARK: Printing


    /**
     This typedef represents the required signature for your provided callback
     function should you wish to register one with tidySetPrettyPrinterCallback().
     Your callback function will be provided with the following parameters.

     - parameters:
     - report: An instance conforming to TidyPPProgessProtocol.
     - returns:
     Your callback function will return `true` if Tidy should include the report
     report in its own output sink, or `false` if Tidy should suppress it.
     */

    typealias TidyPPProgress = ( _ report: TidyPPProgressProtocol ) -> Void


    /**
     This function informs Tidy to use the specified callback for tracking the
     pretty-printing process progress.

     # See also:
     - `tidyPPProgressRecords(forTidyDoc:)`
     - `<TidyDelegateProtocol>tidyReports(pprint:)`

     - parameters:
     - tdoc: The `TidyDoc` for which you are setting the callback.
     - callback: The function to be called.
     - returns:
     True or false indicating the success or failure of setting the callback.
     */
    func tidySetPrettyPrinterCallback( _ tdoc: TidyDoc, _ callback: @escaping TidyPPProgress ) -> Swift.Bool



    /***************************************************************************//**
     ** Functions for parsing markup from a given input source, as well as string
     ** and filename functions for added convenience. HTML/XHTML version determined
     ** from input.
     ******************************************************************************/
    // MARK: - Document Parse:


    /**
     Parse markup in named file.

     - parameters:
     - tdoc: The tidy document to use for parsing.
     - filename: The path and filename to parse.
     - returns:
     Returns the highest of `2` indicating that errors were present in the
     document, `1` indicating warnings, and `0` in the case of everything being
     okay.
     */
    func tidyParseFile( _ tdoc: TidyDoc, _ filename: String ) -> Int


    /**
     Parse markup from the standard input.

     - parameters:
     - tdoc: The tidy document to use for parsing.
     - returns:
     Returns the highest of `2` indicating that errors were present in the
     docment, `1` indicating warnings, and `0` in the case of everything being
     okay.
     */
    func tidyParseStdin( _ tdoc: TidyDoc ) -> Int


    /**
     Parse markup in given string.
     - returns: Returns the highest of `2` indicating that errors were present in
     the docment, `1` indicating warnings, and `0` in the case of
     everything being okay.
     */
    func tidyParseString( _ tdoc: TidyDoc, _ content: String ) -> Int



    /***************************************************************************//**
     ** After parsing the document, you can use these functions to attempt cleanup,
     ** repair, get additional diagnostics, and determine the document type.
     ******************************************************************************/
    // MARK: - Clean, Diagnostics, and Repair:


    /**
     Execute configured cleanup and repair operations on parsed markup.

     - parameters:
     - tdoc: The tidy document to use.
     - returns:
     An integer representing the status.
     */
    func tidyCleanAndRepair( _ tdoc: TidyDoc ) -> Int


    /**
     Run configured diagnostics on parsed and repaired markup.

     - precondition: You must call `tidyCleanAndRepair()` before using this
     function.

     - parameters:
     - tdoc: The tidy document to use.
     - returns:
     An integer representing the status.
     */
    func tidyRunDiagnostics( _ tdoc: TidyDoc ) -> Int


    /**
     Reports the document type into the output sink.

     - parameters:
     - tdoc: The tidy document to use.
     - returns:
     An integer representing the status.
     */
    func tidyReportDoctype( _ tdoc: TidyDoc ) -> Int


    /***************************************************************************//**
     ** Save currently parsed document to the given output sink. File name
     ** and string/buffer functions provided for convenience.
     ******************************************************************************/
    // MARK: - Document Save Functions:


    /**
     Save the tidy document to the named file.

     - parameters:
     - tdoc: The tidy document to save.
     - filenam: The destination file name.
     - returns:
     An integer representing the status.
     */
    func tidySaveFile( _ tdoc: TidyDoc, _ filename: String )


    /**
     Save the tidy document to standard output (FILE*).

     - parameters:
     - tdoc: The tidy document to save.
     - returns:
     An integer representing the status.
     */
    func tidySaveStdout( _ tdoc: TidyDoc ) -> Int


    /**
     Save the tidy document to given TidyBuffer object.

     - parameters:
     - tdoc: The tidy document to save.
     - buf: The buffer to place the output.
     - returns:
     An integer representing the status.
     */
    func tidySaveBuffer( _ tdoc: TidyDoc, _ buf: TidyBufferProtocol ) -> Int


    /**
     Save current settings to named file. Only writes non-default values.

     - parameters:
     - tdoc: The tidy document to save.
     - cfgfil: The filename to save the configuration to.
     - returns:
     An integer representing the status.
     */
    func tidyOptSaveFile( _ tdoc: TidyDoc, _ cfgfil: String ) -> Int


    /***************************************************************************//**
     ** A parsed (and optionally repaired) document is represented by Tidy as a
     ** tree, much like a W3C DOM. This tree may be traversed using these
     ** functions. The following snippet gives a basic idea how these functions
     ** can be used.
     **
     ** @code{.c}
     ** void dumpNode( TidyNode tnod, int indent ) {
     **   TidyNode child;
     **
     **   for ( child = tidyGetChild(tnod); child; child = tidyGetNext(child) ) {
     **     ctmbstr name;
     **     switch ( tidyNodeGetType(child) ) {
     **     case TidyNode_Root:       name = "Root";                    break;
     **     case TidyNode_DocType:    name = "DOCTYPE";                 break;
     **     case TidyNode_Comment:    name = "Comment";                 break;
     **     case TidyNode_ProcIns:    name = "Processing Instruction";  break;
     **     case TidyNode_Text:       name = "Text";                    break;
     **     case TidyNode_CDATA:      name = "CDATA";                   break;
     **     case TidyNode_Section:    name = "XML Section";             break;
     **     case TidyNode_Asp:        name = "ASP";                     break;
     **     case TidyNode_Jste:       name = "JSTE";                    break;
     **     case TidyNode_Php:        name = "PHP";                     break;
     **     case TidyNode_XmlDecl:    name = "XML Declaration";         break;
     **
     **     case TidyNode_Start:
     **     case TidyNode_End:
     **     case TidyNode_StartEnd:
     **     default:
     **       name = tidyNodeGetName( child );
     **       break;
     **     }
     **     assert( name != NULL );
     **     printf( "\%*.*sNode: \%s\\n", indent, indent, " ", name );
     **     dumpNode( child, indent + 4 );
     **   }
     ** }
     **
     ** void dumpDoc( TidyDoc tdoc ) {
     **   dumpNode( tidyGetRoot(tdoc), 0 );
     ** }
     **
     ** void dumpBody( TidyDoc tdoc ) {
     **   dumpNode( tidyGetBody(tdoc), 0 );
     ** }
     ** @endcode
     **
     ** @{
     ******************************************************************************/
    // MARK: - Document Tree:
    // MARK: Nodes for Document Sections


    /**
     Get the root node.

     - parameters:
     - tdoc: The document to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetRoot( _ tdoc: TidyDoc ) -> TidyNode?


    /**
     Get the HTML node.

     - parameters:
     - tdoc: The document to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetHtml( _ tdoc: TidyDoc ) -> TidyNode?


    /**
     Get the HEAD node.

     - parameters:
     - tdoc: The document to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetHead( _ tdoc: TidyDoc ) -> TidyNode?


    /**
     Get the BODY node.

     - parameters:
     - tdoc: The document to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetBody( _ tdoc: TidyDoc ) -> TidyNode?


    // MARK: Relative Nodes


    /**
     Get the parent of the indicated node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetParent( _ tnod: TidyNode ) -> TidyNode?


    /**
     Get the child of the indicated node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetChild( _ tnod: TidyNode ) -> TidyNode?


    /**
     Get the next sibling node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetNext( _ tnod: TidyNode ) -> TidyNode?


    /**
     Get the previous sibling node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a tidy node.
     */
    func tidyGetPrev( _ tnod: TidyNode ) -> TidyNode?


    // MARK: Miscellaneous Node Functions


    /**
     Remove the indicated node.

     - parameters:
     - tdoc: The tidy document from which to remove the node.
     - tnod: The node to remove.
     - returns:
     Returns the next tidy node.
     */
    func tidyDiscardElement( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> TidyNode?


    // MARK: Node Attribute Functions


    /**
     Get the first attribute.

     - parameters:
     - tnod: The node for which to get attributes.
     - returns:
     Returns an instance of TidyAttr.
     */
    func tidyAttrFirst( _ tnod: TidyNode ) -> TidyAttr?


    /**
     Get the next attribute.

     - parameters:
     - tattr: The current attribute, so the next one can be returned.
     - returns:
     Returns and instance of TidyAttr.
     */
    func tidyAttrNext( _ tattr: TidyAttr ) -> TidyAttr?


    /**
     Get the name of a TidyAttr instance.
     - parameters:
     - tattr: The tidy attribute to query.
     - returns:
     Returns a string indicating the name of the attribute.
     */
    func tidyAttrName( _ tattr: TidyAttr ) -> String


    /**
     Get the value of a TidyAttr instance.

     - parameters:
     - tattr: The tidy attribute to query.
     - returns: Returns a string indicating the value of the attribute.
     */
    func tidyAttrValue( _ tattr: TidyAttr ) -> String


    /**
     Discard an attribute.

     - parameters:
     - tdoc: The tidy document from which to discard the attribute.
     - tnod: The node from which to discard the attribute.
     - tattr: The attribute to discard.
     */
    func tidyAttrDiscard( _ tdoc: TidyDoc, _ tnod: TidyNode, _ tattr: TidyAttr ) -> Void


    /**
     Get the attribute ID given a tidy attribute.

     - parameters:
     - tattr: The attribute to query.
     - returns:
     Returns the TidyAttrId of the given attribute.
     */
    func tidyAttrGetId( _ tattr: TidyAttr ) -> TidyAttrId


    /**
     Indicates whether or not a given attribute is an event attribute.

     - parameters:
     - tattr: The attribute to query.
     - returns:
     Returns a bool indicating whether or not the attribute is an event.
     **/
    func tidyAttrIsEvent( _ tattr: TidyAttr ) -> Swift.Bool


    /**
     Get an instance of TidyAttr by specifying an attribute ID.

     - parameters:
     - tnod: The node to query.
     - attId: The attribute ID to find.
     - returns:
     Returns a TidyAttr instance.
     */
    func tidyAttrGetById( _ tnod: TidyNode, _ attId: TidyAttrId )


    // MARK: Additional Node Interrogation


    /**
     Get the type of node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns the type of node as TidyNodeType.
     */
    func tidyNodeGetType( _ tnod: TidyNode ) -> TidyNodeType


    /**
     Get the name of the node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a string indicating the name of the node.
     */
    func tidyNodeGetName( _ tnod: TidyNode ) -> String


    /**
     Indicates whether or not a node is a text node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a bool indicating whether or not the node is a text node.
     */
    func tidyNodeIsText( _ tnod: TidyNode ) -> Swift.Bool


    /**
     Indicates whether or not the node is a propriety type.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - returns:
     Returns a bool indicating whether or not the node is a proprietary type.
     */
    func tidyNodeIsProp( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> Swift.Bool


    /**
     Indicates whether or not a node represents an HTML header element, such
     as h1, h2, etc.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns a bool indicating whether or not the node is an HTML header.
     */
    func tidyNodeIsHeader( _ tnod: TidyNode ) -> Swift.Bool


    /**
     Indicates whether or not the node has text.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - returns:
     Returns the type of node as TidyNodeType.
     */
    func tidyNodeHasText( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> Swift.Bool


    /**
     Gets the text of a node and places it into the given TidyBuffer.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - buf: [out] A TidyBuffer used to receive the node's text.
     - returns:
     Returns a bool indicating success or not.
     */
    func tidyNodeGetText( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: TidyBufferProtocol ) -> Swift.Bool


    /**
     Gets the text of a node and returns it as a string.

     - Note:
     This signature is a convenience addition to CLibTidy for SwLibTidy.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - returns:
     Returns a string with the node's text.
     */
    func tidyNodeGetText( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> String


    /**
     Get the value of the node. This copies the unescaped value of this node into
     the given TidyBuffer as UTF-8.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - buf: [out] A TidyBuffer used to receive the node's text.
     - returns:
     Returns a bool indicating success or not.
     */
    func tidyNodeGetValue( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: TidyBufferProtocol ) -> Swift.Bool


    /**
     Get the value of the node. This copies the unescaped value of this node into
     the given TidyBuffer as UTF-8.

     - Note:
     This signature is a convenience addition to CLibTidy for SwLibTidy.

     - parameters:
     - tdoc: The document to query.
     - tnod: The node to query.
     - returns:
     Returns a string with the node's value, on nil if the node type doesn't
     have a value.
     */
    func tidyNodeGetValue( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> String?


    /**
     Get the tag ID of the node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns the tag ID of the node as TidyTagId.
     */
    func tidyNodeGetId( _ tnod: TidyNode ) -> TidyTagId


    /**
     Get the line number where the node occurs.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns the line number.
     */
    func tidyNodeLine( _ tnod: TidyNode ) -> UInt


    /**
     Get the column location of the node.

     - parameters:
     - tnod: The node to query.
     - returns:
     Returns the column location of the node.
     */
    func tidyNodeColumn( _ tnod: TidyNode ) -> UInt


    /***************************************************************************//**
     ** These functions serve to manage message codes, i.e., codes that are used
     ** Tidy and communicated via its callback filters to represent reports and
     ** dialogue that Tidy emits.
     **
     ** - Note: These codes only reflect complete messages, and are specifically
     **     distinct from the internal codes that are used to lookup individual
     **     strings for localization purposes.
     ******************************************************************************/
    // MARK: - Message Key Management:


    /**
     Given a message code, return the text key that represents it.

     - Note: despite the name of this method, it's used to fetch the message key
     for *any* of Tidy's messages. Because the messages have origins from
     different enums in the original C source code, this method can only take
     a UInt. Although you should always use enums rather than raw values, in
     this case you must use EnumLabel.rawValue.

     - parameters:
     - code: The message code to lookup.
     - returns:
     The string representing the error code.
     */
    func tidyErrorCodeAsKey( _ code: UInt32 ) -> String


    /**
     Given a text key representing a message code, return the UInt that
     represents it.

     - Note: We establish that for external purposes, the API will ensure that
     string keys remain consistent. *Never* count on the integer value
     of a message code. Always use this function to ensure that the
     integer is valid if you need one.

     - parameters:
     - code: The string representing the error code.
     - returns:
     Returns an integer that represents the error code, which can be
     used to lookup Tidy's built-in strings. If the provided string does
     not have a matching message code, then UINT_MAX will be returned.
     */
    func tidyErrorCodeFromKey( _ code: String ) -> UInt32

    /**
     Returns on array of `UInt`, where each `UInt` represents an message code
     available in Tidy. These `UInt` values map to message codes in one CLibTidy's
     various enumerations. In general, you must never count on these values, and
     always use the enum label. This utility is generally only useful for
     documentation purposes.

     - Note: This Swift array replaces the CLibTidy `getErrorCodeList()` and
     `getNextErrorCode()` functions, as it is much more natural to deal with
     Swift array types when using Swift.

     - returns:
     An array of `UInt`, if any.
     */
    func getErrorCodeList() -> [UInt]


    /***************************************************************************//**
     ** These functions help manage localization in Tidy. Note that these implement
     ** native CLibTidy localization; you'd probably want to implement your own
     ** mechanism to use native macOS localization.
     ******************************************************************************/
    // MARK: - Localization Support:
    // MARK: Tidy's Locale


    /**
     Tells Tidy to use a different language for output.

     - parameters:
     - languageCode: A Windows or POSIX language code, and must match a
     `TIDY_LANGUAGE` for an installed language.
     - returns:
     Indicates that a setting was applied, but not necessarily the specific
     request, i.e., true indicates a language and/or region was applied. If
     `es_mx` is requested but not installed, and `es` is installed, then `es`
     will be selected and this function will return `true`. However the opposite
     is not true; if `es` is requested but not present, Tidy will not try to
     select from the `es_XX` variants.
     */
    func tidySetLanguage( _ languageCode: String ) -> Swift.Bool


    /**
     Gets the current language used by Tidy.

     - returns:
     Returns a string indicating the currently set language.
     */
    func tidyGetLanguage() -> String


    // MARK: Locale Mappings


    /**
     Returns a dictionary of mappings between Windows legacy locale names to
     POSIX locale names.

     - Note: This Swift array replaces the CLibTidy functions
     `getWindowsLanguageList()` and `getNextWindowsLanguage()`, as it is much
     more natural to deal with Swift array types when using Swift.

     - returns:
     Returns a dictionary with key names representing a Windows locale name,
     and values representing the equivalent POSIX locale. Note that this
     relationship may be many to one, in that multiple Windows locale names
     refer to the same POSIX mapping.
     */
    func getWindowsLanguageList() -> [ String : String ]


    // MARK: Getting Localized Strings


    /**
     Provides a string given `messageType` in the current localization for
     `quantity`. Some strings have one or more plural forms, and this function
     will ensure that the correct singular or plural form is returned for the
     specified quantity.

     - parameters:
     - messageType: The message type.
     - quantity: The quantity.
     - returns:
     Returns the desired string.
     */
    func tidyLocalizedStringN( _ messageType: tidyStrings, _ quantity: UInt ) -> String


    /**
     Provides a string given `messageType` in the current localization for the
     single case.

     - parameters:
     - messageType: The message type.
     - returns:
     Returns the desired string.
     */
    func tidyLocalizedString( _ messageType: tidyStrings ) -> String


    /**
     Provides a string given `messageType` in the default localization (which
     is `en`).

     - parameters:
     - messageType: The message type.
     - returns:
     Returns the desired string.
     */
    func tidyDefaultString( _ messageType: tidyStrings ) -> String


    /**
     Returns an array of `UInt`, each of which serves as a key to a CLibTidy string.

     - Note: These are provided for documentation generation purposes, and probably
     aren't of much use to the average LibTidy implementor. This list includes
     _every_ localizable string in Tidy, including strings that are used
     internally to build other strings, which are NOT part of the API. It is
     suggested that you use getErrorCodeList() for all public API strings.

     - Note: This Swift array replaces the CLibTidy functions `getStringKeyList()`
     and `getNextStringKey()`, as it is much more natural to deal with Swift
     array types when using Swift.

     - returns:
     Returns an array of `UInt`.
     */
    func getStringKeyList() -> [UInt]


    // MARK: Available Languages


    /**
     Returns an array of `String`, each of which indicates an installed CLibTidy
     language.

     - Note: This Swift array replaces the CLibTidy functions
     `getInstalledLanguageList()` and `getNextInstalledLanguage()`, as it is much
     more natural to deal with Swift array types when using Swift.

     - returns:
     Returns an array of `String`.
     */
    func getInstalledLanguageList() -> [String]


    /******************************************************************************
     ** Convenience Methods
     **************************************************************************** */
    // MARK: - Convenience and Delegate Methods:

    /**
     Set the delegate for an instance of TidyDoc.
     */
    func tidySetDelegate( anObject: TidyDelegateProtocol, forTidyDoc: TidyDoc )

    /**
     Returns an array of objects containing everything that could have been passed
     to the ConfigCallback. This convenience method avoids having to use your own
     callback or delegate method to collect this data.

     - parameters:
     - forTidyDoc: the document for which you want to retrieve unrecognized
     configuration records.
     - returns:
     Returns an array of objects conforming to the TidyConfigReportProtocol,
     by default, of type TidyConfigReport. You can instruct SwLibTidy to use
     a different class via setTidyConfigRecords(toClass:forTidyDoc:).
     */
    func tidyConfigRecords( forTidyDoc: TidyDoc ) -> [TidyConfigReportProtocol]


    /**
     Allows you to set an alternate class to be used in the tidyConfigRecords()
     array. The alternate class must conform to TidyConfigReportProtocol, and
     might be used if you want a class to provide more sophisticated management
     of these unrecognized options.

     - parameters:
     - forTidyDoc: The TidyDoc for which you are setting the class.
     - toClass: The class that you want to use to collect unrecognized options.
     - returns:
     Returns true or false indicating whether or not the class could be set.
     */
    func setTidyConfigRecords( toClass: TidyConfigReportProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


    /**
     Returns an array of every TidyMessage that was generated during every stage
     of a TidyDoc life-cycle. This convenience method allows you to access this
     data without having to use a callback or delegate method.

     - parameters:
     - forTidyDoc: the document for which you want to retrieve messages.
     - returns:
     Returns an array of objects conforming to the TidyMessageProtocol, by
     default, of type TidyMessageContainer. You can instruct SwLibTidy to use
     a different class via setTidyMessageRecords(toClass:forTidyDoc:).
     */
    func tidyMessageRecords( forTidyDoc: TidyDoc ) -> [TidyMessageProtocol]


    /**
     Allows you to set an alternate class to be used in the tidyMessageRecords()
     array. The alternate class must conform to TidyMessageProtocol, and might be
     used if you want a class to provide more sophisticated management of messages.

     - parameters:
     - forTidyDoc: The TidyDoc for which you are setting the class.
     - toClass: The class that you want to use to collect messages.
     - returns:
     Returns true or false indicating whether or not the class could be set.
     */
    func setTidyMessageRecords( toClass: TidyMessageProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


    /**
     Returns an array of every Pretty Printing Progress update that was generated
     during the pretty printing process. This convenience method allows you to
     access this data without having to use a callback or delegate method.

     - parameters:
     - forTidyDoc: the document for which you want to retrieve data.
     - returns:
     Returns an array of objects conforming to the TidyPPProgressProtocol, by
     default, of type TidyPPProgressReport. You can instruct SwLibTidy to use
     a different class via setTidyPPProgressRecords(toClass:forTidyDoc:).
     */
    func tidyPPProgressRecords( forTidyDoc: TidyDoc ) -> [TidyPPProgressProtocol]


    /**
     Allows you to set an alternate class to be used in the tidyPPProgressRecords()
     array. The alternate class must conform to TidyPPProgressProtocol, and might be
     used if you want a class to provide more sophisticated management of reports.

     - parameters:
     - forTidyDoc: The TidyDoc for which you are setting the class.
     - toClass: The class that you want to use to collect data.
     - returns:
     Returns true or false indicating whether or not the class could be set.
     */
    func setTidyPPProgressRecords( toClass: TidyPPProgressProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


}

@objc public class TidyDocument: NSObject {

    private var doc = tidyCreate()

//    public init?() {
//    }
//
    deinit {
        if let doc = doc {
            tidyRelease( doc )
        }
    }

    // Can't return optional to objc.
    @objc public func getOptionId( forName: String ) -> TidyOptionId {

        return tidyOptGetIdForName( forName )!
    }

    @objc public func getHello() -> String {
        return "Hello, Jim"
    }

    
}




