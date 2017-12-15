/******************************************************************************

    TidyDocumentProtocol.swift
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
      CLibTidy's TidyDoc is re-described as a set of protocols, and many of the
      functions have been made into type properties and methods, and instance
      properties and methods. Additionally, where methods are used, Swift and
      Cocoa conventions and types are used instead of C/Tidy types.

      Some functions that have been incorporated into the TidyDocumentProtocol
      aren't otherwise necessary in Swift, but have been provided for
      Objective-C, which cannot use Swift top level functions. For example,
      `tidyReleaseDate()`.

      While SwTidyLib is written to be as "pure Swift" as possible (assuming
      the open-source Foundation is used on other platforms), TidyKit is
      unabashedly designed for use with macOS and iOS, as well as offering
      full support for Objective-C (even if this limits some of the potential
      API magic offered by Swift).

    Unimplemented Functions
      Functions with built-in Cocoa equivalents have not been included, e.g.,
      `tidyFileExists()`.

      Also abstracted away is all notion of STDIN and STDOUT. All non-URL
      I/O is string-based, and anything that would have been written to an
      error file, stderr, or stdout by CLibTidy is available as a string. Use
      Cocoa for any type of output that you may need.

      Convenience option value setters such as `TidySetInCharEncoding()` have
      been omitted. While these are conveniences for the CLibTidy CLI app,
      they clutter the interface any your own application can implement them
      trivially.

 ******************************************************************************/

import Foundation


/******************************************************************************
 This composed protocol encompasses all of the separate protocols that make up
 a TidyDocument.
 ******************************************************************************/
@objc public protocol TidyDocumentProtocol: TidyDocumentTidyingProtocol,
                                            TidyDocumentTypePropertiesProtocol,
                                            TidyDocumentCallbackProtocol,
                                            TidyDocumentOptionsProtocol,
                                            TidyNodeProtocol,
                                            TidyLocaleProtocol,
                                            TidyRecordsProtocol {}


/******************************************************************************
 The heart of Tidy, provides functionality for setting text, parsing and
 cleaning it, and running diagnostics.
 ******************************************************************************/
@objc public protocol TidyDocumentTidyingProtocol: AnyObject {

    /** The default initializer for classes adopting this protocol. */
    init()

    /** Intialize with NSData to populate `sourceText`. */
    init( withData: Data )

    /** Initialize with a file to populate `sourceText`. */
    init( withURL: NSURL )

    /** The text to be tidied. */
    var sourceText: String { get set }

    /** The parsed, tidied text. */
    var tidyText: String { get }

    /** The version of HTML that was output. */
    var tidyDetectedHtmlVersion: String { get }

    /** Indicates whether the output document is or isn't XHTML. */
    var tidyDetectedXhtml: Bool { get }

    /**
     Indicates whether or not the input document was XML. If `TidyXml` tags is
     true, or there was an XML declaration in the input document, then this
     function will return `true`.
     */
    var tidyDetectedGenericXml: Bool { get }

    /** Returns more complete information about errors after tidying. */
    var tidyErrorSummary: String { get }

    /** Returns more general information about markup after tidying. */
    var tidyGeneralInfo: String { get }

}


/******************************************************************************
 Provide Swift top-level functions as type properties. Although Swift
 applications could simply use the SwLibTidy top-level functions, these
 are not available to Objective-C, and so are made available here.
 ******************************************************************************/
@objc public protocol TidyDocumentTypePropertiesProtocol: AnyObject {

    /** Get the release date for the current library. */
    static var tidyReleaseDate: String { get }

    /** Get the version number for the current library. */
    static var tidyLibraryVersion: String { get }

    /** Get the platform name from the current library. */
    static var tidyPlatform: String { get }

}


/******************************************************************************
 Provide a protocol for using LibTidy's callbacks and delegate.
 - Note: the required callback function signatures can be found in the
     typealias in `SwLibTidy.swift`.
 ******************************************************************************/
@objc public protocol TidyDocumentCallbackProtocol: AnyObject {

    /** The delegate for this instance of the TidyDocument. */
//    var delegate: SwLibTidyDelegateProtocol? { get set }

    /**
     Allows the host application to store a reference to an object instance.
     This can be useful for callbacks, such as saving a reference to `self`.
     Because callbacks in Swift can only call back to a global function (not
     an instance method), it will be useful to know (in your callback) which
     instance of your class generated the callback.
    */
    var appData: AnyObject? { get set }


    /**
     Applications using TidyLib may want to augment command-line and
     configuration file options. Setting this callback allows a LibTidy
     application developer to examine command-line and configuration file
     options after LibTidy has examined them and failed to recognize them.

     # See also:
     - `tidyConfigRecords`
     - `<TidyDelegateProtocol>tidyReports(unknownOption:)`

     - parameters:
       - configCallback: The name of a function of type `TidyConfigCallback` to
           serve as your callback.
     - returns:
         Returns `true` upon success.
     */
//    func tidySet( configCallback: @escaping TidyConfigCallback ) -> Bool


    /**
     Applications using TidyLib may want to be informed when changes to options
     are made. Temporary changes made internally by Tidy are not reported, but
     permanent changes made by Tidy (such as indent-spaces or output-encoding)
     will be reported.

     # See also:
     - `<TidyDelegateProtocol>tidyReports(optionChanged:forTidyDoc:)`

     - parameters:
       - configChangeCallback: The name of a function of type
           TidyConfigChangeCallback() to serve as your callback.
     - returns:
         Returns true upon success setting the callback.
     */
    func tidySet( configChangeCallback: @escaping TidyConfigChangeCallback ) -> Bool


    /**
     This function informs Tidy to use the specified callback to send reports.

     # See also:
     - `tidyMessageRecords`
     - `<TidyDelegateProtocol>tidyReports(message:)`

     - parameters:
       - messageCallback: A pointer to your callback function of type
           `TidyMessageCallback`.
     - returns:
         A boolean indicating success or failure setting the callback.
     */
//    func tidySet( messageCallback: @escaping TidyMessageCallback ) -> Bool


    /**
     This function informs Tidy to use the specified callback for tracking the
     pretty-printing process progress.

     # See also:
     - `tidyPPProgressRecords`
     - `<TidyDelegateProtocol>tidyReports(pprint:)`

     - parameters:
       - prettyPrinterCallback: The function to be called.
     - returns:
         True or false indicating the success or failure of setting the callback.
     */
//    func tidySet( prettyPrinterCallback: @escaping TidyPPProgress ) -> Bool

}


/******************************************************************************
 Utilities for managing TidyOptionProtocol instances that belong to the
 TidyDocument as a whole.
 ******************************************************************************/
@objc public protocol TidyDocumentOptionsProtocol: AnyObject {

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



    /**
     Save current configuration to named file. Only writes non-default values.

     - parameters:
     - tdoc: The tidy document to save.
     - cfgfil: The filename to save the configuration to.
     - returns:
     An integer representing the status.
     */
    func tidyOptSaveFile( _ tdoc: TidyDoc, _ cfgfil: String ) -> Int


    /**
     Reset all options to their default values.

     - parameters:
     - tdoc: The tidy document for which to reset all values.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptResetAllToDefault() -> Bool


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
    func tidyOptSnapshot() -> Bool


    /**
     Apply a snapshot of config settings to a document.

     - parameters:
     - tdoc: The tidy document for which to apply a snapshot.
     - returns:
     Returns a bool indicating success or failure.
     */
    func tidyOptResetToSnapshot() -> Bool


    /**
     Any settings different than default?

     - parameters:
     - tdoc: The tidy document to check.
     - returns:
     Returns a bool indicating whether or not a difference exists.
     */
    func tidyOptDiffThanDefault() -> Bool


    /**
     Any settings different than snapshot?

     - parameters:
     - tdoc: The tidy document to check.
     - returns:
     Returns a bool indicating whether or not a difference exists.
     */
    func tidyOptDiffThanSnapshot() -> Bool


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


}


/******************************************************************************
 Provides functionality for working with document nodes.
 ******************************************************************************/
@objc public protocol TidyNodeProtocol: AnyObject {


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
    func tidyAttrIsEvent( _ tattr: TidyAttr ) -> Bool


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
//    func tidyNodeGetText( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: SwLibTidyBufferProtocol ) -> Swift.Bool


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
//    func tidyNodeGetValue( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: SwLibTidyBufferProtocol ) -> Swift.Bool


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

}


/******************************************************************************
 Provides utilities for managing LibTidy's internal locale support. It's
 recommended that your classes use Cocoa-native localization features instead
 of using LibTidy's built-in localization.
 ******************************************************************************/
@objc public protocol TidyLocaleProtocol: AnyObject {


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

}


/******************************************************************************
 Provides properties for getting the results of Tidying processes.
 ******************************************************************************/
@objc public protocol TidyRecordsProtocol: AnyObject {


    /******************************************************************************
     ** Convenience Methods
     **************************************************************************** */
    // MARK: - Convenience Methods:

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
//    func tidyConfigRecords( forTidyDoc: TidyDoc ) -> [SwLibTidyConfigReportProtocol]


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
//    func setTidyConfigRecords( toClass: SwLibTidyConfigReportProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


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
//    func tidyMessageRecords( forTidyDoc: TidyDoc ) -> [SwLibTidyMessageProtocol]


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
//    func setTidyMessageRecords( toClass: SwLibTidyMessageProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


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
//    func tidyPPProgressRecords( forTidyDoc: TidyDoc ) -> [SwLibTidyPPProgressProtocol]


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
//    func setTidyPPProgressRecords( toClass: SwLibTidyPPProgressProtocol.Type, forTidyDoc: TidyDoc ) -> Swift.Bool


}


public protocol JimProtocol {
    associatedtype JimType: AnyObject = String
    var jimvar: JimType { get }
}

@objc public class JimClass: NSObject, JimProtocol {
    public var jimvar: String = "Hello from JimClass."
}


@objc public protocol SwiftProtocol {
    var value: String { get }
}

@objc public class SwiftClass: NSObject, SwiftProtocol {
    public var value: String { return "Hello from Swiftclass" }
}

@objc public protocol TestHelloProtocol {
    var hello: String { get }
}

@objc public protocol TestGoodbyeProtocol {
    var goodbye: String { get }
}

@objc public protocol TestProtocol: TestHelloProtocol, TestGoodbyeProtocol {}


@objc public class TestClass: NSObject, TestProtocol {

    public var hello: String
    public var goodbye: String

    public override init() {
        self.hello = "Hello"
        self.goodbye = "Goodbye"
        super.init()
    }

    @objc public func sayHello() {
        print( hello )
    }

    @objc public func sayGoodbye() {
        print( goodbye )
    }

    /* Not visible in Objective-C! */
    @objc public func getSwiftProtocol() -> SwiftProtocol {
        return SwiftClass()
    }

    @objc public func getSwiftClass() -> SwiftClass {
        return SwiftClass()
    }

}




