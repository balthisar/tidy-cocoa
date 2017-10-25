/******************************************************************************

	SwLibTidy.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      Provide a low-level, highly procedural wrapper to the nearly the entirety
      of CLibTidy in order to simplify the use of CLibTidy in Swift console and
      GUI applications, and as a basis for developing high-level, object-
      oriented classes for macOS and iOS. Its goals are to:
        - Use Swift-native types, including for the use of callbacks/closures
          and for the storage of context data. Although procedure, some minimal
          supplementary classes are used to abstract C data structures.
        - Provide arrays of information instead of depending on CLibTidy's
          iterator mechanism.
        - Maintain full compatibility with Objective-C (when wrapped into a
          class).
        - Provide some additional tools and functionality useful within Swift.
 
    Unsupported APIs
      Support for custom memory allocators is currently missing; CLibTidy will
      use its default memory allocators. Custom memory allocators, if needed,
      are best written in C for compatibility.
 
      No support for custom input and output sources/sinks is present, and it's
      very unlikely that they would be needed for a modern, full-featured 
      operating system. If needed, they are best written in C for compatibility.
 
      TidyReportFilter and TidyReportCallback are not supported as being
      deprecated (although not yet marked as such in CLibTidy source). Instead,
      use the modern, extensible TidyMessageCallback features that this library
      wraps.
 
      tidySaveString() is not supported; there's not really a use case in Swift;
      use tidySaveBuffer() instead.

      tidyParseBuffer() is not supported; there's no really a use case in Swift;
      use tidyParseString() instead.
 
    Localization API
      CLibTidy will always perform in its default (`en`) locale unless you use
      the localization API to change it. This might be suitable if you are
      writing a command line tool, but it's recommended to use native
      localization features instead. CLibTidy's source includes gettext
      compatible `.po` files that can be converted to `.strings` if needed.
 
    Important Linking Notes:
      There are both static and dylib targets for this framework. Generally
      distribution is made simpler if your GUI apps use the framework proper
      (dynamic library), and console applications link statically (because
      console applications are not bundles).

    Compiling Notes
      The tidy-html5 target uses tidy-html5 as distributed, and that project
      keeps track of version numbers in `version.txt`. Thus the tidy-html5
      target in this project "compiles" `version.txt` using a build rule that
      generates `tidy-html5-version.h` with the correct version number and
      release date, which is then used via Build Settings -> Prefix Target.
 
    Reference Notes
      There's no substitute for reading the source code, particularly CLibTidy
      public header files in order to understand all of the possible C enum
      values and their meanings.

 ******************************************************************************/

import Foundation
import CLibTidy

/******************************************************************************
 ** "Globals,", used within this file.
 **************************************************************************** */
// MARK: - Globals


/** Enforce a minimum LibTidy version for compatibility. */
fileprivate let MINIMUM_LIBTIDY_VERSION = "5.5.70"


/******************************************************************************
 ** Instances of these types are returned by LibTidy API functions, however
 ** they are opaque; you cannot see into them, and must use accessor functions
 ** to access the contents.
 **************************************************************************** */
// MARK: - Opaque Types


/**
 Instances of this represent a Tidy document, which encapsulates everything
 there is to know about a single Tidy session. Many of the API functions
 return instance of TidyDoc, or expect instances as parameters.
*/
public typealias TidyDoc = CLibTidy.TidyDoc

/**
 Instances of this represent a Tidy configuration option, which contains
 useful data about these options. Functions related to configuration options
 return or accept instances of this type.
*/
public typealias TidyOption = CLibTidy.TidyOption

public typealias TidyOptionId = CLibTidy.TidyOptionId

/** 
 Single nodes of a TidyDocument are represented by this datatype. It can be
 returned by various API functions, or accepted as a function argument.
*/
public typealias TidyNode = CLibTidy.TidyNode

/**
 Attributes of a TidyNode are represented by this data type. The public API
 functions related to attributes work with this type.
*/
public typealias TidyAttr = CLibTidy.TidyAttr

/**
 Instances of this type represent messages generated by Tidy in reference
 to your document. This API is available in some of Tidy's message callback
 functions.
*/
public typealias TidyMessage = CLibTidy.TidyMessage

/** 
 Instances of this type represent the arguments that compose part of the
 message represented by TidyMessage. These arguments have an API to query
 information about them.
*/
public typealias TidyMessageArgument = CLibTidy.TidyMessageArgument


// MARK: - Basic Operations -

// MARK: Instantiation and Destruction


/**
 The primary creation of a document instance. Instances of a `TidyDoc` are used
 throughout the API as a token to represent a particular document. When done
 using a `TidyDoc` instance, be sure to `tidyRelease(myTidyDoc)` in order
 to free related memory.
 
 - returns:
     Returns a `TidyDoc` instance.
*/
public func tidyCreate() -> TidyDoc? {
    
    // Perform CLibTidy version checking, because we count on some of the
    // newer API's.
    let versionCurrent: String = tidyLibraryVersion()
    
    let vaMin = MINIMUM_LIBTIDY_VERSION.components(separatedBy: ".").map { Int.init($0) ?? 0 }
    let vaCurrent = versionCurrent.components(separatedBy: ".").map { Int.init($0) ?? 0 }
    
    if vaCurrent.lexicographicallyPrecedes(vaMin) {
        debugPrint( "LibTidy: oldest recommended version is \(MINIMUM_LIBTIDY_VERSION), but you have linked against \(versionCurrent)." )
    }
    
    // This is the only real "wrapper" part!
    guard let tdoc = CLibTidy.tidyCreate() else { return nil }

    // Create some extra storage to attach to Tidy's AppData.
    let appData: ApplicationData = ApplicationData.init()

    // Convert it to a pointer that we can store, increasing the retain count.
    let ptr = UnsafeMutableRawPointer( Unmanaged.passRetained(appData).toOpaque() )

    // Now attach it to Tidy's AppData.
    CLibTidy.tidySetAppData(tdoc, ptr)
    
    
    /* Now we're going to usurp all of Tidy's callbacks so that we can use them
     * for our own purposes, such as building Swift-like data structures that
     * can avoid the need for user callbacks. The user can still specify a
     * callback, but our internal callbacks will call them.
     */
    
    guard yes == CLibTidy.tidySetConfigCallback( tdoc, { tdoc, option, value in

        guard let option = option,
            let value = value,
            let ptrStorage = CLibTidy.tidyGetAppData( tdoc )
            else { return no }
        
        let strOption = String( cString: option )
        let strValue = String( cString: value )

        let storage: ApplicationData = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()

        storage.configCallbackRecords.append( TidyConfigReport.init( withValue: strValue, forOption: strOption) )

        if let callback = storage.configCallback {
            return callback( tdoc!, strOption, strValue ) ? yes : no
        } else {
            return no
        }
    }) else { tidyRelease( tdoc ); return nil }
    
    guard yes == CLibTidy.tidySetMessageCallback( tdoc, { tmessage in
        
        guard
            let tmessage = tmessage,
            let tdoc = CLibTidy.tidyGetMessageDoc( tmessage ),
            let ptrStorage = CLibTidy.tidyGetAppData( tdoc )
            else { return yes }
        
        let storage = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()
        
        if let callback = storage.tidyMessageCallback {
            return callback( tmessage ) ? yes : no
        } else {
            return yes
        }
    }) else { tidyRelease( tdoc ); return nil }
    
    guard yes == CLibTidy.tidySetPrettyPrinterCallback( tdoc, { tdoc, line, col, destLine in
        
        guard
            let tdoc = tdoc,
            let ptrStorage = CLibTidy.tidyGetAppData( tdoc )
            else { return }
        
        let storage = Unmanaged<ApplicationData>
            .fromOpaque(ptrStorage)
            .takeUnretainedValue()
        
        if let callback = storage.tidyPPCallback {
            callback(  tdoc, UInt(line), UInt(col), UInt(destLine) )
        }
    }) else { tidyRelease( tdoc ); return nil }
    
    return tdoc
}

/**
 Free all memory and release the `TidyDoc`. The `TidyDoc` cannot be used after
 this call.
 
 - parameters:
   - tdoc: The `TidyDoc` to free.
*/

public func tidyRelease( _ tdoc: TidyDoc ) {
    
    // Release our auxilliary structure.
    if let ptr = CLibTidy.tidyGetAppData(tdoc) {
        
        // Decreasing the retain count should cause it to dealloc.
        let _: ApplicationData = Unmanaged<ApplicationData>
            .fromOpaque(ptr)
            .takeRetainedValue()
    }

    CLibTidy.tidyRelease( tdoc )
}


// MARK: Host Application Data


/**
 Allows the host application to store a reference to an object instance with
 each `TidyDoc` instance. This can be useful for callbacks, such as saving a
 reference to `self` within the Tidy document. Because callbacks in Swift can
 only call back to a global function (not an instance method), it will be
 useful to know (in your callback) which instance of your class generated the
 callback.
 
 - parameters:
   - tdoc: The `TidyDoc` for which you are setting the reference.
   - appData: A reference to self.
*/
public func tidySetAppData( _ tdoc: TidyDoc, _ appData: AnyObject ) {
    
    // Turn our opaque reference to an ApplicationData into a real instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return }
    
    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    storage.appData = appData
}

/**
 Returns the reference previously stored with `tidySetAppData()`.
 
 - parameters:
   - tdoc: document where data has been stored.
 - returns:
     The reference to the object previously stored.
*/
public func tidyGetAppData( _ tdoc: TidyDoc ) -> AnyObject? {
    
    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return nil }
    
    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()
    
    return storage.appData
}


// MARK: CLibTidy Version Information


/** 
 Get the release date for the current library.
 
 - returns: 
     The string representing the release date.
*/
public func tidyReleaseDate() -> String {
    
    return String( cString: CLibTidy.tidyReleaseDate() )
}

/** 
 Get the version number for the current library.
 
 - returns:
     The string representing the version number.
*/
public func tidyLibraryVersion() -> String {
    
    return String( cString: CLibTidy.tidyLibraryVersion() )
}

/**
 Get the platform name from the current library.

 - returns:
     An optional string indicating the platform on which LibTidy was built.
 */
public func tidyPlatform() -> String? {

    guard let platform = CLibTidy.tidyPlatform() else { return nil }

    return String( cString: platform )
}


// MARK: - Diagnostics and Repair Status

/**
 Get status of current document.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns: 
     Returns the highest of `2` indicating that errors were present in the
     docment, `1` indicating warnings, and `0` in the case of everything
     being okay.
*/
public func tidyStatus( _ tdoc: TidyDoc ) -> Int {
    
    return Int(CLibTidy.tidyStatus( tdoc ))
}

/** 
 Gets the version of HTML that was output, as an integer, times 100. For
 example, HTML5 will return 500; HTML4.0.1 will return 401.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns the HTML version number (x100).
*/
public func tidyDetectedHtmlVersion( _ tdoc: TidyDoc ) -> Int {
    
    return Int(CLibTidy.tidyDetectedHtmlVersion( tdoc ))
}


/**
 Indicates whether the output document is or isn't XHTML.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns `true` if the document is an XHTML type.
*/
public func tidyDetectedXhtml( _ tdoc: TidyDoc ) -> Swift.Bool {

    return CLibTidy.tidyDetectedXhtml( tdoc ) == yes ? true : false
}


/**
 Indicates whether or not the input document was XML. If `TidyXml` tags is
 true, or there was an XML declaration in the input document, then this
 function will return `true`.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns `true` if the input document was XML.
*/
public func tidyDetectedGenericXml( _ tdoc: TidyDoc ) -> Swift.Bool {
    
    return CLibTidy.tidyDetectedGenericXml( tdoc ) == yes ? true : false
}


/**
 Indicates the number of `TidyError` messages that were generated. For any
 value greater than `0`, output is suppressed unless `TidyForceOutput` is set.
 
 - parameters
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns the number of `TidyError` messages that were generated.
*/
public func tidyErrorCount( _ tdoc: TidyDoc ) -> UInt {
    
    return UInt(CLibTidy.tidyErrorCount( tdoc ))
}

/**
 Indicates the number of `TidyWarning` messages that were generated.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns: 
     Returns the number of `TidyWarning` messages that were generated.
*/
public func tidyWarningCount( _ tdoc: TidyDoc ) -> UInt {
    
    return UInt(CLibTidy.tidyWarningCount( tdoc ))
}


/**
 Indicates the number of `TidyAccess` messages that were generated.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns the number of `TidyAccess` messages that were generated.
*/
public func tidyAccessWarningCount( _ tdoc: TidyDoc ) -> UInt {
    
    return UInt(CLibTidy.tidyAccessWarningCount( tdoc ))
}


/**
 Indicates the number of configuration error messages that were generated.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
 - returns:
     Returns the number of configuration error messages that were generated.
*/
public func tidyConfigErrorCount( _ tdoc: TidyDoc ) -> UInt {
    
    return UInt(CLibTidy.tidyConfigErrorCount( tdoc ))
}


/**
 Write more complete information about errors to current error sink.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
*/
public func tidyErrorSummary( _ tdoc: TidyDoc ) {
    
    CLibTidy.tidyErrorSummary( tdoc )
}


/**
 Write more general information about markup to current error sink.
 
 - parameters:
   - tdoc: An instance of a `TidyDoc` to query.
*/
public func tidyGeneralInfo( _ tdoc: TidyDoc ) {
    
    CLibTidy.tidyGeneralInfo( tdoc )
}


/** 
 Load an ASCII Tidy configuration file and set the configuration per its
 contents.
 
 - parameters:
   - tdoc: The `TidyDoc` to which to apply the configuration.
   - configFile: The complete path to the file to load.
 - returns: 
     Returns `0` upon success, or any other value if there was an error.
*/
public func tidyLoadConfig( _ tdoc: TidyDoc, _ configFile: String ) -> Int {
    
    return Int( CLibTidy.tidyLoadConfig( tdoc, configFile ) )
}


/** 
 Load a Tidy configuration file with the specified character encoding, and
 set the configuration per its contents.
 
 - parameters:
   - tdoc: The `TidyDoc` to which to apply the configuration.
   - configFile: The complete path to the file to load.
   - charenc: The encoding to use. See struct `_enc2iana` for valid values.
 - returns: 
     Returns `0` upon success, or any other value if there was an error.
*/
public func tidyLoadConfigEnc( _ tdoc: TidyDoc, _ configFile: String, _ charenc: String ) -> Int {
    
    return Int( CLibTidy.tidyLoadConfigEnc( tdoc, configFile, charenc ) )
}


/**
 Determine whether or not a particular file exists. On Unix systems, the use
 of the tilde to represent the user's home directory is supported.
 
 - parameters:
   - tdoc: The `TidyDoc` on whose behalf you are checking.
   - filename: The path to the file whose existence you wish to check.
 - returns: 
     Returns `true` or `false`, indicating whether or not the file exists.
*/
public func tidyFileExists( _ tdoc: TidyDoc, _ filename: String ) -> Swift.Bool {
    
    return CLibTidy.tidyFileExists( tdoc, filename ) == yes ? true : false
}


// MARK: - Configuration, File, and Encoding Operations
// MARK: - Character Encoding


/** 
 Set the input/output character encoding for parsing markup. Valid values
 include `ascii`, `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`,
 `utf16le`, `utf16be`, `utf16`, `big5`, and `shiftjis`. These values are not
 case sensitive.
 
 - Note: This is the same as using `TidySetInCharEncoding()` and
     `TidySetOutCharEncoding()` to set the same value.
 
 - parameters:
   - tdoc: The `TidyDoc` for which you are setting the encoding.
   - encnam: The encoding name as described above.
 - returns:
     Returns `0` upon success, or a system standard error number `EINVAL`.
*/
public func tidySetCharEncoding( _ tdoc: TidyDoc, _ encnam: String ) -> Int {
    
    return Int( CLibTidy.tidySetCharEncoding( tdoc, encnam ) )
}


/**
 Set the input encoding for parsing markup.  Valid values include `ascii`,
 `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
 `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.
 
 - parameters:
   - tdoc: The `TidyDoc` for which you are setting the encoding.
   - encnam: The encoding name as described above.
 - returns:
     Returns `0` upon success, or a system standard error number `EINVAL`.
*/
public func tidySetInCharEncoding( _ tdoc: TidyDoc, _ encnam: String ) -> Int {
    
    return Int( CLibTidy.tidySetInCharEncoding( tdoc, encnam ) )
}


/**
 Set the output encoding for writing markup.  Valid values include `ascii`,
 `latin1`, `raw`, `utf8`, `iso2022`, `mac`, `win1252`, `utf16le`, `utf16be`,
 `utf16`, `big5`, and `shiftjis`. These values are not case sensitive.
 
 - Note: Changing this value _after_ processing a document will _not_ change
     the results present in any buffers.
 
 - parameters:
   - tdoc: The `TidyDoc` for which you are setting the encoding.
   - encnam: The encoding name as described above.
 - returns:
     Returns `0` upon success, or a system standard error number `EINVAL`.
*/
public func tidySetOutCharEncoding( _ tdoc: TidyDoc, _ encnam: String ) -> Int {
    
    return Int( CLibTidy.tidySetOutCharEncoding( tdoc, encnam ) )
}

 
// MARK: Configuration Callback Functions


/** 
 This typealias represents the required signature for your provided callback
 function should you wish to register one with `tidySetConfigCallback()`. Your
 callback function will be provided with the following parameters.
 
 - parameters:
   - tdoc: The `TidyDoc` trying to set a configuration.
   - option: The option name that was provided.
   - value: The option value that was provided
 - returns: 
     Your callback function will return `true` if it handles the provided
     option, or `false` if it does not. In the latter case, Tidy will issue an 
     error indicating the unknown configuration option.
*/
public typealias TidyConfigCallback = ( _ tdoc: TidyDoc, _ option: String, _ value: String ) -> Swift.Bool


/**
 Applications using TidyLib may want to augment command-line and configuration 
 file options. Setting this callback allows a LibTidy application developer to 
 examine command-line and configuration file options after LibTidy has examined
 them and failed to recognize them.
 
 - parameters:
   - tdoc: The document to apply the callback to.
   - swiftCallback: The name of a function of type `TidyConfigCallback` to
       serve as your callback.
 - returns:
     Returns `true` upon success.
*/
public func tidySetConfigCallback( _ tdoc: TidyDoc, _ swiftCallback: @escaping TidyConfigCallback ) -> Swift.Bool {
    
    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }
    
    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()
    
    storage.configCallback = swiftCallback;
    
    return true
}

// MARK: Option ID Discovery


/**
 Get ID of given Option
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns:
     The `TidyOptionId` of the given option.
*/
public func tidyOptGetId( _ opt: TidyOption ) -> TidyOptionId? {

    let optId = CLibTidy.tidyOptGetId( opt )

    return optId == N_TIDY_OPTIONS ? nil : optId
}


/**
 Returns the `TidyOptionId` (C enum value) by providing the name of a Tidy
 configuration option.
 
 - parameters:
   - optnam: The name of the option ID to retrieve.
 - returns: 
     The `TidyOptionId` of the given `optname`.
*/
public func tidyOptGetIdForName( _ optnam: String) -> TidyOptionId? {

    let optId = CLibTidy.tidyOptGetIdForName( optnam )

    return optId == N_TIDY_OPTIONS ? nil : optId
}


// MARK: Getting Instances of Tidy Options


/**
 Returns an array of `TidyOption` tokens containing each Tidy option, which are
 an opaque type that can be interrogated with other LibTidy functions.
 
 - Note: This function will return internal-only option types including
     `TidyInternalCategory`; you should *never* use these. Always ensure
     that you use `tidyOptGetCategory()` before assuming that an option
     is okay to use in your application.
 
 - Note: This Swift array replaces the CLibTidy functions `tidyGetOptionList()`
     and `TidyGetNextOption()`, as it is much more natural to deal with Swift
     array types when using Swift.
 
 - parameters:
   - tdoc: The tidy document for which to retrieve options.
 - returns:
     Returns an array of `TidyOption` opaque tokens.
*/
public func tidyGetOptionList( _ tdoc: TidyDoc ) -> [TidyOption] {
    
    var it: TidyIterator? = CLibTidy.tidyGetOptionList( tdoc )
    
    var result: [TidyOption] = []
    
    while ( it != nil ) {
        
        if let opt = CLibTidy.tidyGetNextOption(tdoc, &it) {
            result.append(opt)
        }
    }
    
    return result
}


/**
 Retrieves an instance of `TidyOption` given a valid `TidyOptionId`.
 
 - parameters:
   - tdoc: The document for which you are retrieving the option.
   - optId: The `TidyOptionId` to retrieve.
 - returns:
     An instance of `TidyOption` matching the provided `TidyOptionId`.
*/
public func tidyGetOption( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> TidyOption? {

    /* CLibTidy can return garbage on this call, so check it ourselves. */
    if optId.rawValue <= TidyUnknownOption.rawValue || optId.rawValue >= N_TIDY_OPTIONS.rawValue {
        return nil;
    }

    return CLibTidy.tidyGetOption( tdoc, optId )
}

 
/**
 Returns an instance of `TidyOption` by providing the name of a Tidy
 configuration option.
 
 - parameters:
   - tdoc: The document for which you are retrieving the option.
   - optnam: The name of the Tidy configuration option.
 - returns: 
     The `TidyOption` of the given `optname`.
*/
public func tidyGetOptionByName( _ tdoc: TidyDoc, _ optnam: String ) -> TidyOption? {

    return CLibTidy.tidyGetOptionByName( tdoc, optnam )
}


// MARK: Information About Options


/**
 Get name of given option
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns:
     The name of the given option.
*/
public func tidyOptGetName( _ opt: TidyOption ) -> String {
 
    return String( cString: CLibTidy.tidyOptGetName( opt ) )
}

 
/**
 Get datatype of given option
 
 - parameters:
   - opt: An instance of a TidyOption to query.
 - returns: 
     The `TidyOptionType` of the given option.
*/
public func tidyOptGetType( _ opt: TidyOption ) -> TidyOptionType {
 
    return CLibTidy.tidyOptGetType( opt )
}


/** 
 Is Option read-only? Some options (mainly internal use only options) are
 read-only.
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns: 
     Returns `true` or `false` depending on whether or not the specified
     option is read-only.
*/
public func tidyOptIsReadOnly( _ opt: TidyOption ) -> Swift.Bool {

    return CLibTidy.tidyOptIsReadOnly( opt ) == yes ? true : false
}

 
/**
 Get category of given option
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns: 
     The `TidyConfigCategory` of the specified option.
*/
public func tidyOptGetCategory( _ opt: TidyOption ) -> TidyConfigCategory {
 
    return CLibTidy.tidyOptGetCategory( opt )
}

 
/** 
 Get default value of given option as a string
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns:
     A string indicating the default value of the specified option.
*/
public func tidyOptGetDefault( _ opt: TidyOption ) -> String? {

    if let result = CLibTidy.tidyOptGetDefault( opt ) {
        return String( cString: result )
    }

    return nil
}

 
/**
 Get default value of given option as an unsigned integer
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns:
     An unsigned integer indicating the default value of the specified option.
*/
public func tidyOptGetDefaultInt( _ opt: TidyOption ) -> UInt {
 
    return UInt( CLibTidy.tidyOptGetDefaultInt( opt ) )
}

 
/**
 Get default value of given option as a Boolean value
 
 - parameters:
   - opt: An instance of a `TidyOption` to query.
 - returns:
     A boolean indicating the default value of the specified option.
*/
public func tidyOptGetDefaultBool( _ opt: TidyOption ) -> Swift.Bool {
 
    return tidyOptGetDefaultBool( opt ) == yes ? true : false
}


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
public func tidyOptGetPickList( _ opt: TidyOption ) -> [String] {
    
    var it: TidyIterator? = CLibTidy.tidyOptGetPickList( opt )
    
    var result : [String] = []
    
    while ( it != nil ) {
        
        if let pick = CLibTidy.tidyOptGetNextPick( opt, &it) {
            result.append( String( cString:pick ) )
        }
    }
    
    return result
}


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
public func tidyOptGetValue( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String? {

    if let result = CLibTidy.tidyOptGetValue( tdoc, optId ) {
        return String( cString: result )
    }

    return nil
}

 
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
public func tidyOptSetValue( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: String ) -> Swift.Bool {

    return CLibTidy.tidyOptSetValue( tdoc, optId, val ) == yes ? true : false
}

 
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
public func tidyOptParseValue( _ tdoc: TidyDoc, _ optnam: String, _ val: String ) -> Swift.Bool {

    return CLibTidy.tidyOptParseValue( tdoc, optnam, val ) == yes ? true : false
}

 
/** 
 Get current option value as an integer.
 
 - parameters:
   - tdoc: The tidy document for which to get the value.
   - optId: The option ID to get.
 - returns:
     Returns the integer value of the specified option.
*/
public func tidyOptGetInt( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> UInt {

    return UInt( CLibTidy.tidyOptGetInt( tdoc, optId) )
}

 
/**
 Set option value as an integer.
 
 - parameters
   - tdoc: The tidy document for which to set the value.
   - optId: The option ID to set.
   - val: The value to set.
 - returns:
     Returns a bool indicating success or failure.
*/
public func tidyOptSetInt( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: UInt32 ) -> Swift.Bool {

    return CLibTidy.tidyOptSetInt( tdoc, optId, UInt(val) ) == yes ? true : false
}

 
/** 
 Get current option value as a Boolean.
 
 - parameters:
   - tdoc: The tidy document for which to get the value.
   - optId: The option ID to get.
 - returns:
     Returns a bool indicating the value.
*/
public func tidyOptGetBool( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> Swift.Bool {
 
    return CLibTidy.tidyOptGetBool( tdoc, optId ) == yes ? true : false
}

 
/** 
 Set option value as a Boolean.
 
 - parameters:
   - tdoc: The tidy document for which to set the value.
   - optId: The option ID to set.
   - val: The value to set.
 - returns:
     Returns a bool indicating success or failure.
*/
public func tidyOptSetBool( _ tdoc: TidyDoc, _ optId: TidyOptionId, _ val: Swift.Bool ) -> Swift.Bool {
 
    return CLibTidy.tidyOptSetBool( tdoc, optId, val == true ? yes : no ) == yes ? true : false
}

 
/**
 Reset option to default value by ID.
 
 - parameters:
   - tdoc: The tidy document for which to reset the value.
   - opt: The option ID to reset.
 - returns:
     Returns a bool indicating success or failure.
*/
public func tidyOptResetToDefault( _ tdoc: TidyDoc, _ opt: TidyOptionId ) -> Swift.Bool {

    return CLibTidy.tidyOptResetToDefault( tdoc, opt ) == yes ? true : false
}

 
/**
 Reset all options to their default values.
 
 - parameters:
   - tdoc: The tidy document for which to reset all values.
 - returns: 
     Returns a bool indicating success or failure.
*/
public func tidyOptResetAllToDefault( _ tdoc: TidyDoc ) -> Swift.Bool {

    return CLibTidy.tidyOptResetAllToDefault( tdoc ) == yes ? true : false
}

 
/**
 Take a snapshot of current config settings.
 
 - parameters:
   - tdoc: The tidy document for which to take a snapshot.
 - returns:
     Returns a bool indicating success or failure.
*/
public func tidyOptSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool {
 
    return CLibTidy.tidyOptSnapshot( tdoc ) == yes ? true : false
}

 
/**
 Apply a snapshot of config settings to a document, such as after document
 processing. This will ensure that any values which Tidy may have changed
 are back to the intended configuration.
 
 - parameters:
   - tdoc: The tidy document for which to apply a snapshot.
 - returns: 
     Returns a bool indicating success or failure.
*/
public func tidyOptResetToSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool {
 
    return CLibTidy.tidyOptResetToSnapshot( tdoc ) == yes ? true : false
}

 
/**
 Any settings different than default?
 
 - parameters:
   - tdoc: The tidy document to check.
 - returns:
     Returns a bool indicating whether or not a difference exists.
*/
public func tidyOptDiffThanDefault( _ tdoc: TidyDoc ) -> Swift.Bool {
 
    return CLibTidy.tidyOptDiffThanDefault( tdoc ) == yes ? true : false
}

 
/**
 Any settings different than snapshot?
 
 - parameters:
   - tdoc: The tidy document to check.
 - returns:
     Returns a bool indicating whether or not a difference exists.
*/
public func tidyOptDiffThanSnapshot( _ tdoc: TidyDoc ) -> Swift.Bool {
 
    return CLibTidy.tidyOptDiffThanSnapshot( tdoc ) == yes ? true : false
}

 
/**
 Copy current configuration settings from one document to another.
 
 - parameters:
   - tdocTo: The destination tidy document.
   - tdocFrom: The source tidy document.
 - returns:
     Returns a bool indicating success or failure.
*/
public func tidyOptCopyConfig( _ tdocTo: TidyDoc, _ tdocFrom: TidyDoc ) -> Swift.Bool {
 
    return CLibTidy.tidyOptCopyConfig( tdocTo, tdocFrom ) == yes ? true : false
}

 
/**
 Get character encoding name. Used with `TidyCharEncoding`, 
 `TidyOutCharEncoding`, and `TidyInCharEncoding`.
 
 - parameters:
   - tdoc: The tidy document to query.
   - optId: The option ID whose value to check.
 - returns: 
     The encoding name as a string for the specified option.
*/
public func tidyOptGetEncName( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String {
 
    return String( cString: CLibTidy.tidyOptGetEncName( tdoc, optId ) )
}

 
/**
 Get the current pick list value for the option ID, which can be useful for
 enum types.
 
 - parameters:
   - tdoc: The tidy document to query.
   - optId: The option ID whose value to check.
 - returns: 
     Returns a string indicating the current value of the given option.
*/
public func tidyOptGetCurrPick( _ tdoc: TidyDoc, _ optId: TidyOptionId ) -> String {
 
    return String( cString: CLibTidy.tidyOptGetCurrPick( tdoc, optId ) )
}


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
public func tidyOptGetDeclTagList( _ tdoc: TidyDoc, forOptionId optId: TidyOptionId ) -> [String] {
    
    var it: TidyIterator? = CLibTidy.tidyOptGetDeclTagList( tdoc )
    
    var result : [String] = []
    
    while ( it != nil ) {
        
        if let tag = CLibTidy.tidyOptGetNextDeclTag( tdoc, optId, &it) {
            result.append( String( cString: tag ) )
        }
    }
    
    return result
}

 
// MARK: Option Documentation


/** 
 Get the description of the specified option.
 
 - parameters:
   - tdoc: The tidy document to query.
   - opt: The option ID of the option.
 - returns: 
     Returns a string containing a description of the given option.
*/
public func tidyOptGetDoc( _ tdoc: TidyDoc, _ opt: TidyOption ) -> String {
    
    return String( cString: CLibTidy.tidyOptGetDoc( tdoc, opt ) )
}


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
public func tidyOptGetDocLinksList( _ tdoc: TidyDoc, _ opt: TidyOption ) -> [TidyOption] {
    
    var it: TidyIterator? = CLibTidy.tidyOptGetDocLinksList( tdoc, opt )
    
    var result : [TidyOption] = []
    
    while ( it != nil ) {
        
        if let opt = CLibTidy.tidyOptGetNextDocLinks( tdoc, &it) {
            result.append( opt )
        }
    }
    
    return result
}


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
public typealias CFilePointer = UnsafeMutablePointer<FILE>


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
public func tidySetEmacsFile( _ tdoc: TidyDoc, _ filePath: String ) {

    CLibTidy.tidySetEmacsFile( tdoc, filePath )
}

/** 
 Get the file path to use for reports when `TidyEmacs` is being used. This
 function provides a proper interface for using the hidden, internal-only
 `TidyEmacsFile` configuration option.
 
 - parameters:
   - tdoc: The tidy document for which you want to fetch the file path.
 - returns:
     Returns a string indicating the file path.
*/
public func tidyGetEmacsFile( _ tdoc: TidyDoc ) -> String {

    return String( cString: CLibTidy.tidyGetEmacsFile( tdoc ) )
}

 
// MARK: Error Sink


/** 
 Set error sink to named file.

 - parameters:
   - tdoc: The document to set.
   - errfilname: The file path to send output.
 - returns: 
     Returns a file handle.
*/
@discardableResult public func tidySetErrorFile( _ tdoc: TidyDoc, _ errfilnam: String ) -> CFilePointer {
 
    return CLibTidy.tidySetErrorFile( tdoc, errfilnam )
}


/**
 Set error sink to given buffer.
 
 - parameters:
   - tdoc: The document to set.
   - errbuf: An instance of TidyBuffer to provide output.
 - returns:
     Returns 0 upon success or a standard error number.
*/
public func tidySetErrorBuffer( _ tdoc: TidyDoc, errbuf: TidyBufferProtocol ) -> Int {

    return Int( CLibTidy.tidySetErrorBuffer( tdoc, errbuf.tidyBuffer) )
}


/***************************************************************************//**
 A sophisticated and extensible callback to filter or collect messages
 reported by Tidy. It returns only an opaque type `TidyMessage` for every
 report and dialogue message, and this message can be queried with the
 TidyMessageCallback API, below. Note that unlike the older filters, this
 callback exposes *all* output that LibTidy emits (excluding the console
 application, which is a client of LibTidy).
 ******************************************************************************/
// MARK: Error and Message Callbacks - TidyMessageCallback


/**
 This typealias represents the required signature for your provided callback
 function should you wish to register one with tidySetMessageCallback().
 Your callback function will be provided with the following parameters.
 
 - parameters:
   - tmessage: An opaque type used as a token against which other API calls can
       be made.
 - returns: Your callback function will return `true` if Tidy should include the
     report in its own output sink, or `false` if Tidy should suppress it.
*/
public typealias TidyMessageCallback = ( _ tmessage: TidyMessage ) -> Swift.Bool

 
/** 
 This function informs Tidy to use the specified callback to send reports.
 
 - parameters:
   - tdoc: The tidy document for which the callback applies.
   - filtCallback: A pointer to your callback function of type 
       `TidyMessageCallback`.
 - returns:
     A boolean indicating success or failure setting the callback.
 */
public func tidySetMessageCallback( _ tdoc: TidyDoc, filtCallback: @escaping TidyMessageCallback ) -> Swift.Bool {

    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }
    
    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()
    
    storage.tidyMessageCallback = filtCallback;
    
    return true
}


/***************************************************************************//**
 ** When using `TidyMessageCallback` you will be supplied with a TidyMessage 
 ** object, which is used as a token to be interrogated with the following
 ** API before the callback returns.
 ** Note: Upon returning from the callback, this object is destroyed so do
 ** not attempt to copy it, or keep it around, or use it in any way.
 ******************************************************************************/
// MARK: TidyMessageCallback API


/**
 Get the tidy document this message comes from.
 
 - parameters:
   - tmessage: Specify the message that you are querying.
 - returns:
     Returns the TidyDoc that generated the message.
*/
public func tidyGetMessageDoc( _ tmessage: TidyMessage ) -> TidyDoc {

    return CLibTidy.tidyGetMessageDoc( tmessage )
}

/**
 Get the message code.
 
 - parameters:
   - tmessage: Specify the message that you are querying.
 - returns: 
     Returns a code representing the message. This code can be used directly
     with the localized strings API; however we never make any guarantees about
     the value of these codes. For code stability don't store this value in your
     own application. Instead use the enum field or use the message key string
     value.
*/
public func tidyGetMessageCode( _ tmessage: TidyMessage ) -> UInt {

    return UInt( CLibTidy.tidyGetMessageCode( tmessage ) )
}

 
/** 
 Get the message key string.
 
 - parameters:
   - tmessage: Specify the message that you are querying.
 - returns: 
     Returns a string representing the message. This string is intended to be
     stable by the LibTidy API, and is suitable for use as a key in your own
     applications.
*/
public func tidyGetMessageKey( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageKey( tmessage ))
}

 
/**
 Get the line number the message applies to.
 
 - parameters:
   - tmessage: Specify the message that you are querying.
 - returns: 
     Returns the line number, if any, that generated the message.
*/
public func tidyGetMessageLine( _ tmessage: TidyMessage ) -> Int {

    return Int( CLibTidy.tidyGetMessageLine( tmessage) )
}

 
/** 
 Get the column the message applies to.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the column number, if any, that generated the message.
*/
public func tidyGetMessageColumn( _ tmessage: TidyMessage ) -> Int {

    return Int( CLibTidy.tidyGetMessageColumn( tmessage ) )
}

 
/**
 Get the TidyReportLevel of the message.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns a TidyReportLevel indicating the severity or status of the
     message.
*/
public func tidyGetMessageLevel( _ tmessage: TidyMessage ) -> TidyReportLevel {

    return CLibTidy.tidyGetMessageLevel( tmessage )
}

 
/** 
 Get the default format string, which is the format string for the message
 in Tidy's default localization (en_us).
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the default localization format string of the message.
*/
public func tidyGetMessageFormatDefault( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageFormatDefault( tmessage ) )
}

 
/**
 Get the localized format string. If a localized version of the format string
 doesn't exist, then the default version will be returned.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the localized format string of the message.
*/
public func tidyGetMessageFormat( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageFormat( tmessage ) )
}

 
/** 
 Get the message with the format string already completed, in Tidy's
 default localization.

 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the message in the default localization.
*/
public func tidyGetMessageDefault( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageDefault( tmessage ) )
}

 
/** 
 Get the message with the format string already completed, in Tidy's
 current localization.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the message in the current localization.
*/
public func tidyGetMessage( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessage( tmessage ) )
}

 
/** 
 Get the position part part of the message in the default language.

 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the positional part of a string as Tidy would display it
     in the console application.
*/
public func tidyGetMessagePosDefault( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessagePosDefault( tmessage ) )
}

 
/** 
 Get the position part part of the message in the current language.

 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the positional part of a string as Tidy would display it
     in the console application.
*/
public func tidyGetMessagePos( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessagePos( tmessage ) )
}

 
/**
 Get the prefix part of a message in the default language.

 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the message prefix part of a string as Tidy would display
     it in the console application.
*/
public func tidyGetMessagePrefixDefault( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessagePrefixDefault( tmessage ) )
}

 
/**
 Get the prefix part of a message in the current language.

 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the message prefix part of a string as Tidy would display
     it in the console application.
*/
public func tidyGetMessagePrefix( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessagePrefix( tmessage ) )
}

 
/**
 Get the complete message as Tidy would emit it in the default localization.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the complete message just as Tidy would display it on the
     console.
*/
public func tidyGetMessageOutputDefault( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageOutputDefault( tmessage ) )
}

 
/**
 Get the complete message as Tidy would emit it in the current localization.
 
 - parameter tmessage: Specify the message that you are querying.
 - returns: Returns the complete message just as Tidy would display it on the
     console.
*/
public func tidyGetMessageOutput( _ tmessage: TidyMessage ) -> String {

    return String( cString: CLibTidy.tidyGetMessageOutput( tmessage ) )
}


/***************************************************************************//**
 ** When using `TidyMessageCallback` you will be supplied with a TidyMessage
 ** object which can be used as a token against which to query using this API.
 ** This API deals strictly with _arguments_ that a message may or may not have;
 ** these are the same arguments that Tidy would apply to a format string in
 ** order to fill in the placeholder fields and deliver a complete report or
 ** dialogue string to you.
 ******************************************************************************/
// MARK: TidyMessageCallback Arguments API


/**
 Returns on array of TidyMessageArgument, where each item represents an argument
 for the specified TidyMessage. You can then use the arguments API to query each
 of these items to deconstruct relevant portions of Tidy's messages.

 - Note: This Swift array replaces the CLibTidy `tidyGetMessageArguments()`
     and `tidyGetNextMessageArgument()` functions, as it is much more natural to
     deal with Swift array types when using Swift.
 
 - parameters
   - tmessage: The `TidyMessage` for which to get arguments.
 - returns:
     An array of `TidyMessageArgument`, if any.
*/
public func tidyGetMessageArguments( forMessage tmessage: TidyMessage ) -> [TidyMessageArgument] {
    
    var it: TidyIterator? = CLibTidy.tidyGetMessageArguments( tmessage )
    
    var result : [TidyMessageArgument] = []
    
    while ( it != nil ) {
        
        if let arg = CLibTidy.tidyGetNextMessageArgument( tmessage, &it ) {
            result.append( arg )
        }
    }
    
    return result
}


/**
 Returns the `TidyFormatParameterType` of the given message argument.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns:
     Returns the type of parameter of type TidyFormatParameterType.
*/
public func tidyGetArgType( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> TidyFormatParameterType {

    var ptrArg: TidyMessageArgument? = arg
    return CLibTidy.tidyGetArgType( tmessage, &ptrArg )
}

 
/**
 Returns the format specifier of the given message argument. The memory for
 this string is cleared upon termination of the callback, so do be sure to
 make your own copy.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns:
     Returns the format specifier string of the given argument.
*/
public func tidyGetArgFormat( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> String {

    var ptrArg: TidyMessageArgument? = arg
    return String( cString: CLibTidy.tidyGetArgFormat( tmessage, &ptrArg ) )
}

 
/**
 Returns the string value of the given message argument. An assertion
 will be generated if the argument type is not a string.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns: 
     Returns the string value of the given argument.
*/
public func tidyGetArgValueString( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> String {

    var ptrArg: TidyMessageArgument? = arg
    return String( cString: CLibTidy.tidyGetArgValueString( tmessage, &ptrArg ) )
}

 
/**
 Returns the unsigned integer value of the given message argument. An
 assertion will be generated if the argument type is not an unsigned int.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns: 
     Returns the unsigned integer value of the given argument.
*/
public func tidyGetArgValueUInt( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> UInt {

    var ptrArg: TidyMessageArgument? = arg
    return UInt( CLibTidy.tidyGetArgValueUInt( tmessage, &ptrArg ) )
}

 
/**
 Returns the integer value of the given message argument. An assertion
 will be generated if the argument type is not an integer.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns: 
     Returns the integer value of the given argument.
*/
public func tidyGetArgValueInt( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> Int {

    var ptrArg: TidyMessageArgument? = arg
    return Int( CLibTidy.tidyGetArgValueInt( tmessage, &ptrArg ) )
}

 
/**
 Returns the double value of the given message argument. An assertion
 will be generated if the argument type is not a double.
 
 - parameters:
   - tmessage: The message whose arguments you want to access.
   - arg: The argument that you are querying.
 - returns: 
     Returns the double value of the given argument.
*/
public func tidyGetArgValueDouble( _ tmessage: TidyMessage, _ arg: TidyMessageArgument ) -> Double {

    var ptrArg: TidyMessageArgument? = arg
    return Double( CLibTidy.tidyGetArgValueDouble( tmessage, &ptrArg ) )
}


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
   - tdoc: Indicates the source tidy document.
   - line Indicates the line in the source document at this point in the process.
   - column: Indicates the column in the source document at this point in the process.
   - destLine: Indicates the line number in the output document at this point in the process.
 - returns: 
     Your callback function will return `true` if Tidy should include the report
     report in its own output sink, or `false` if Tidy should suppress it.
*/

public typealias TidyPPProgress = ( _ tdoc: TidyDoc, _ line: UInt, _ col: UInt, _ destLine: UInt ) -> Void


/**
 This function informs Tidy to use the specified callback for tracking the
 pretty-printing process progress.
 
 - parameters:
   - tdoc: The `TidyDoc` for which you are setting the callback.
   - callback: The function to be called.
 - returns:
     True or false indicating the success or failure of setting the callback.
*/
public func tidySetPrettyPrinterCallback( _ tdoc: TidyDoc, _ callback: @escaping TidyPPProgress ) -> Swift.Bool {
    
    // Let's turn our opaque reference to an ApplicationData into an instance.
    guard let ptrStorage = CLibTidy.tidyGetAppData(tdoc) else { return false }
    
    let storage: ApplicationData = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()
    
    storage.tidyPPCallback = callback;

    return true
}



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
public func tidyParseFile( _ tdoc: TidyDoc, _ filename: String ) -> Int {

        return Int( CLibTidy.tidyParseFile( tdoc, filename ) )
}

 
/**
 Parse markup from the standard input.
 
 - parameters:
   - tdoc: The tidy document to use for parsing.
 - returns:
     Returns the highest of `2` indicating that errors were present in the
     docment, `1` indicating warnings, and `0` in the case of everything being
     okay.
*/
public func tidyParseStdin( _ tdoc: TidyDoc ) -> Int {
    
    return Int( CLibTidy.tidyParseStdin( tdoc ) )
}


/**
 Parse markup in given string.
 - returns: Returns the highest of `2` indicating that errors were present in
     the docment, `1` indicating warnings, and `0` in the case of
     everything being okay.
*/
public func tidyParseString( _ tdoc: TidyDoc, _ content: String ) -> Int {
    
    return Int( CLibTidy.tidyParseString( tdoc, content ) )
}



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
public func tidyCleanAndRepair( _ tdoc: TidyDoc ) -> Int {
 
    return Int( CLibTidy.tidyCleanAndRepair( tdoc ) )
}

 
/**
 Run configured diagnostics on parsed and repaired markup. You must call
 tidyCleanAndRepair() before using this function.
 
 - parameters:
   - tdoc: The tidy document to use.
 - returns:
     An integer representing the status.
*/
public func tidyRunDiagnostics( _ tdoc: TidyDoc ) -> Int {
 
    return Int( CLibTidy.tidyRunDiagnostics( tdoc ) )
}

 
/**
 Reports the document type into the output sink.
 
 - parameters:
   - tdoc: The tidy document to use.
 - returns:
     An integer representing the status.
*/
public func tidyReportDoctype( _ tdoc: TidyDoc ) -> Int {
 
    return Int( CLibTidy.tidyReportDoctype( tdoc ) )
}


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
public func tidySaveFile( _ tdoc: TidyDoc, _ filename: String ) -> Int {
 
    return Int( CLibTidy.tidySaveFile( tdoc, filename ) )
}

 
/**
 Save the tidy document to standard output (FILE*).
 
 - parameters:
   - tdoc: The tidy document to save.
 - returns:
     An integer representing the status.
*/
public func tidySaveStdout( _ tdoc: TidyDoc ) -> Int {
 
    return Int( CLibTidy.tidySaveStdout( tdoc ) )
}
 
 
/**
 Save the tidy document to given TidyBuffer object.
 
 - parameters:
   - tdoc: The tidy document to save.
   - buf: The buffer to place the output.
 - returns: 
     An integer representing the status.
*/
public func tidySaveBuffer( _ tdoc: TidyDoc, _ buf: TidyBufferProtocol ) -> Int {
 
    return Int( CLibTidy.tidySaveBuffer( tdoc, buf.tidyBuffer ) )
}
 

/**
 Save current settings to named file. Only writes non-default values.
 
 - parameters:
   - tdoc: The tidy document to save.
   - cfgfil: The filename to save the configuration to.
 - returns:
     An integer representing the status.
*/
public func tidyOptSaveFile( _ tdoc: TidyDoc, _ cfgfil: String ) -> Int {
 
    return Int( CLibTidy.tidyOptSaveFile( tdoc, cfgfil ) )
}


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
public func tidyGetRoot( _ tdoc: TidyDoc ) -> TidyNode {

    return CLibTidy.tidyGetRoot( tdoc )
}

 
/** 
 Get the HTML node.
 
 - parameters:
   - tdoc: The document to query.
 - returns: 
     Returns a tidy node.
*/
public func tidyGetHtml( _ tdoc: TidyDoc ) -> TidyNode {
 
    return CLibTidy.tidyGetHtml( tdoc )
}
 
 
/** 
 Get the HEAD node.
 
 - parameters:
   - tdoc: The document to query.
 - returns: 
     Returns a tidy node.
*/
public func tidyGetHead( _ tdoc: TidyDoc ) -> TidyNode {
 
    return CLibTidy.tidyGetHead( tdoc )
}
 
 
/** 
 Get the BODY node.
 
 - parameters:
   - tdoc: The document to query.
 - returns:
     Returns a tidy node.
*/
public func tidyGetBody( _ tdoc: TidyDoc ) -> TidyNode {
 
    return CLibTidy.tidyGetBody( tdoc )
}


// MARK: Relative Nodes


/** 
 Get the parent of the indicated node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns a tidy node.
*/
public func tidyGetParent( _ tnod: TidyNode ) -> TidyNode {
 
    return CLibTidy.tidyGetParent( tnod )
}
 
 
/** 
 Get the child of the indicated node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns a tidy node.
*/
public func tidyGetChild( _ tnod: TidyNode ) -> TidyNode {
 
    return CLibTidy.tidyGetChild( tnod )
}
 
 
/**
 Get the next sibling node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns a tidy node.
*/
public func tidyGetNext( _ tnod: TidyNode ) -> TidyNode {
 
    return CLibTidy.tidyGetNext( tnod )
}
 
 
/**
 Get the previous sibling node.
 
 - parameters:
   - tnod: The node to query.
 - returns:
     Returns a tidy node.
*/
public func tidyGetPrev( _ tnod: TidyNode ) -> TidyNode {
 
    return CLibTidy.tidyGetPrev( tnod )
}


// MARK: Miscellaneous Node Functions


/** 
 Remove the indicated node.
 
 - parameters:
   - tdoc: The tidy document from which to remove the node.
   - tnod: The node to remove.
 - returns:
     Returns the next tidy node.
*/
public func tidyDiscardElement( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> TidyNode {
 
    return CLibTidy.tidyDiscardElement( tdoc, tnod )
}


// MARK: Node Attribute Functions


/** 
 Get the first attribute.
 
 - parameters:
   - tnod: The node for which to get attributes.
 - returns:
     Returns an instance of TidyAttr.
*/
public func tidyAttrFirst( _ tnod: TidyNode ) -> TidyAttr {
 
    return CLibTidy.tidyAttrFirst( tnod )
}

 
/**
 Get the next attribute.
 
 - parameters:
   - tattr: The current attribute, so the next one can be returned.
 - returns: 
     Returns and instance of TidyAttr.
*/
public func tidyAttrNext( _ tattr: TidyAttr ) -> TidyAttr {
 
    return CLibTidy.tidyAttrNext( tattr )
}

 
/**
 Get the name of a TidyAttr instance.
 - parameters:
   - tattr: The tidy attribute to query.
 - returns: 
     Returns a string indicating the name of the attribute.
*/
public func tidyAttrName( _ tattr: TidyAttr ) -> String {
 
    return String( cString: CLibTidy.tidyAttrName( tattr ) )
}

 
/** 
 Get the value of a TidyAttr instance.
 
 - parameters:
   - tattr: The tidy attribute to query.
 - returns: Returns a string indicating the value of the attribute.
*/
public func tidyAttrValue( _ tattr: TidyAttr ) -> String {
 
    return String( cString: CLibTidy.tidyAttrValue( tattr ) )
}

 
/**
 Discard an attribute.
 
 - parameters:
   - tdoc: The tidy document from which to discard the attribute.
   - tnod: The node from which to discard the attribute.
   - tattr: The attribute to discard.
*/
public func tidyAttrDiscard( _ tdoc: TidyDoc, _ tnod: TidyNode, _ tattr: TidyAttr ) -> Void {
    
    CLibTidy.tidyAttrDiscard( tdoc, tnod, tattr )
}

 
/** 
 Get the attribute ID given a tidy attribute.
 
 - parameters:
   - tattr: The attribute to query.
 - returns: 
     Returns the TidyAttrId of the given attribute.
*/
public func tidyAttrGetId( _ tattr: TidyAttr ) -> TidyAttrId {
 
    return CLibTidy.tidyAttrGetId( tattr )
}

 
/**
 Indicates whether or not a given attribute is an event attribute.
 
 - parameters:
   - tattr: The attribute to query.
 - returns:
     Returns a bool indicating whether or not the attribute is an event.
 **/
public func tidyAttrIsEvent( _ tattr: TidyAttr ) -> Swift.Bool {
 
    return CLibTidy.tidyAttrIsEvent( tattr ) == yes ? true : false
}

 
/**
 Get an instance of TidyAttr by specifying an attribute ID.
 
 - parameters:
   - tnod: The node to query.
   - attId: The attribute ID to find.
 - returns:
     Returns a TidyAttr instance.
*/
public func tidyAttrGetById( _ tnod: TidyNode, _ attId: TidyAttrId ) -> TidyAttr {
 
    return CLibTidy.tidyAttrGetById( tnod, attId )
}

 
// MARK: Additional Node Interrogation


/**
 Get the type of node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns the type of node as TidyNodeType.
*/
public func tidyNodeGetType( _ tnod: TidyNode ) -> TidyNodeType {
 
    return CLibTidy.tidyNodeGetType( tnod )
}

 
/**
 Get the name of the node.
 
 - parameters:
   - tnod: The node to query.
 - returns:
     Returns a string indicating the name of the node.
*/
public func tidyNodeGetName( _ tnod: TidyNode ) -> String {
 
    return String( cString: CLibTidy.tidyNodeGetName( tnod ) )
}

 
/**
 Indicates whether or not a node is a text node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns a bool indicating whether or not the node is a text node.
*/
public func tidyNodeIsText( _ tnod: TidyNode ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeIsText( tnod ) == yes ? true : false
}

 
/**
 Indicates whether or not the node is a propriety type.
 
 - parameters:
   - tdoc: The document to query.
   - tnod: The node to query.
 - returns:
     Returns a bool indicating whether or not the node is a proprietary type.
*/
public func tidyNodeIsProp( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeIsProp( tdoc, tnod ) == yes ? true : false
}

 
/**
 Indicates whether or not a node represents and HTML header element, such
 as h1, h2, etc.
 
 - parameters:
   - tnod: The node to query.
 - returns:
     Returns a bool indicating whether or not the node is an HTML header.
*/
public func tidyNodeIsHeader( _ tnod: TidyNode ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeIsHeader( tnod ) == yes ? true : false
}

 
/**
 Indicates whether or not the node has text.
 
 - parameters:
   - tdoc: The document to query.
   - tnod: The node to query.
 - returns: 
     Returns the type of node as TidyNodeType.
*/
public func tidyNodeHasText( _ tdoc: TidyDoc, _ tnod: TidyNode ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeHasText( tdoc, tnod ) == yes ? true : false
}

 
/**
 Gets the text of a node and places it into the given TidyBuffer.
 
 - parameters:
   - tdoc: The document to query.
   - tnod: The node to query.
   - buf: [out] A TidyBuffer used to receive the node's text.
 - returns: 
     Returns a bool indicating success or not.
*/
public func tidyNodeGetText( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: TidyBufferProtocol ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeGetText( tdoc, tnod, buf.tidyBuffer ) == yes ? true : false
}

 
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
public func tidyNodeGetValue( _ tdoc: TidyDoc, _ tnod: TidyNode, _ buf: TidyBufferProtocol ) -> Swift.Bool {
 
    return CLibTidy.tidyNodeGetValue( tdoc, tnod, buf.tidyBuffer ) == yes ? true : false
}

 
/**
 Get the tag ID of the node.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns the tag ID of the node as TidyTagId.
*/
public func tidyNodeGetId( _ tnod: TidyNode ) -> TidyTagId {
 
    return CLibTidy.tidyNodeGetId( tnod )
}

 
/**
 Get the line number where the node occurs.
 
 - parameters:
   - tnod: The node to query.
 - returns: 
     Returns the line number.
*/
public func tidyNodeLine( _ tnod: TidyNode ) -> UInt {
 
    return UInt( CLibTidy.tidyNodeLine( tnod ) )
}

 
/**
 Get the column location of the node.
 
 - parameters:
   - tnod: The node to query.
 - returns:
     Returns the column location of the node.
*/
public func tidyNodeColumn( _ tnod: TidyNode ) -> UInt {
 
    return UInt( CLibTidy.tidyNodeColumn( tnod ) )
}

 
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
 
 - parameters:
   - code: The error code to lookup.
 - returns:
     The string representing the error code.
*/
public func tidyErrorCodeAsKey( _ code: uint ) -> String {
 
    return String( cString: CLibTidy.tidyErrorCodeAsKey( code ) )
}

 
/**
 Given a text key representing a message code, return the uint that
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
public func tidyErrorCodeFromKey( _ code: String ) -> UInt {
 
    return UInt( CLibTidy.tidyErrorCodeFromKey( code ) )
}

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
public func getErrorCodeList() -> [UInt] {
    
    var it: TidyIterator? = CLibTidy.getErrorCodeList()
    
    var result : [UInt] = []
    
    while ( it != nil ) {
        result.append( UInt( CLibTidy.getNextErrorCode( &it ) ) )
    }
    
    return result
}


/***************************************************************************//**
 ** These functions help manage localization in Tidy. Note that these implement
 ** native CLibTidy localization; you'd probably want to implement your own
 ** mechanism to use native macOS localization.
 ******************************************************************************/
// MARK: - Localization Support:
// MARK: Tidy's Locale


/** 
 Determines the current locale without affecting the C locale.
 
 - parameters:
   - result: [out] The buffer to use to return the string, or NULL on failure.
 - returns:
     The same buffer for convenience.
*/
public func tidySystemLocale( ) -> String {

    /* CLibTidy has strange calling semantics for this function; it would
       normally allocate `myString` for us, but also returns it as a value.
       This is nice in C where it's a pointer and gives us in-out, but
       doesn't work that way in Swift. */
    let myString: tmbstr? = nil
    return String( cString: CLibTidy.tidySystemLocale( myString ) )
}

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
public func tidySetLanguage( _ languageCode: String ) -> Swift.Bool {

    return CLibTidy.tidySetLanguage( languageCode ) == yes ? true : false
}

 
/**
 Gets the current language used by Tidy.
 
 - returns:
     Returns a string indicating the currently set language.
*/
public func tidyGetLanguage() -> String {

    return String( cString: CLibTidy.tidyGetLanguage() )
}


// MARK: Locale Mappings


/**
 Represents an opaque type we can use for tidyLocaleMapItem, which
 is used to represent items in the language list, and used to access
 the `windowsName()` and the `posixName()`.
*/
public typealias tidyLocaleMapItem = UnsafePointer<CLibTidy.tidyLocaleMapItem?>

 
/**
 Returns an array of `tidyLocaleMapItem` tokens representing a mapping between
 legacy Windows locale names and POSIX names. These tokens can be queried
 against `TidyLangWindowsName` and `TidyLangPosixName`.
 
 - Note: This Swift array replaces the CLibTidy functions
     `getWindowsLanguageList()` and `getNextWindowsLanguage()`, as it is much
     more natural to deal with Swift  array types when using Swift.
 
 - returns:
     Returns an array of `tidyLocaleMapItem` opaque tokens.
*/
public func getWindowsLanguageList() -> [tidyLocaleMapItem] {
    
    var it: TidyIterator? = CLibTidy.getWindowsLanguageList()
    
    var result : [tidyLocaleMapItem] = []
    
    while ( it != nil ) {
        
        if let opt = CLibTidy.getNextWindowsLanguage( &it ) {
            result.append(opt)
        }
    }
    
    return result
}


/**
 Given a `tidyLocalMapItem`, return the Windows name.
 
 - parameters:
   - item: An instance of tidyLocaleMapItem to query.
 - returns: 
     Returns a string with the Windows name of the mapping.
*/
public func TidyLangWindowsName( _ item: tidyLocaleMapItem ) -> String {
 
    return String( cString: CLibTidy.TidyLangWindowsName( item ) )
}

 
/** 
 Given a `tidyLocalMapItem`, return the POSIX name.
 
 - parameters:
   - item: An instance of tidyLocalMapItem to query.
 - returns: 
     Returns a string with the POSIX name of the mapping.
*/
public func TidyLangPosixName( _ item: tidyLocaleMapItem ) -> String {
 
    return String( cString: CLibTidy.TidyLangPosixName( item ) )
}


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
public func tidyLocalizedStringN( _ messageType: tidyStrings, _ quantity: UInt ) -> String {

    /* The actual method doesn't take this type, but a uint. */
    return String( cString: CLibTidy.tidyLocalizedStringN( uint(messageType.rawValue), uint(quantity) ) )
}

 
/**
 Provides a string given `messageType` in the current localization for the
 single case.
 
 - parameters:
   - messageType: The message type.
 - returns:
     Returns the desired string.
*/
public func tidyLocalizedString( _ messageType: tidyStrings ) -> String {

    /* The actual method doesn't take this type, but a uint. */
    return String( cString: CLibTidy.tidyLocalizedString( uint(messageType.rawValue) ) )
}

 
/** 
 Provides a string given `messageType` in the default localization (which
 is `en`).
 
 - parameters:
   - messageType: The message type.
 - returns: 
     Returns the desired string.
*/
public func tidyDefaultString( _ messageType: tidyStrings ) -> String {
 
    return String( cString: CLibTidy.tidyDefaultString( uint(messageType.rawValue) ) )
}

 
/**
 Returns an array of `UInt`, each of which serves as a key to a CLibTidy string.

 - Note: These are provided for documentation generation purposes, and probably
     aren't of much use to the average LibTidy implementor.
 
 - Note: This Swift array replaces the CLibTidy functions `getStringKeyList()`
     and `getNextStringKey()`, as it is much more natural to deal with Swift
     array types when using Swift.
 
 - returns:
     Returns an array of `UInt`.
*/
public func getStringKeyList() -> [UInt] {
    
    var it: TidyIterator? = CLibTidy.getWindowsLanguageList()
    
    var result : [UInt] = []
    
    while ( it != nil ) {
        result.append( UInt( CLibTidy.getNextStringKey( &it ) ) )
    }
    
    return result
}


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
public func getInstalledLanguageList() -> [String] {
    
    var it: TidyIterator? = CLibTidy.getWindowsLanguageList()
    
    var result : [String] = []
    
    while ( it != nil ) {
        
        if let opt = CLibTidy.getNextInstalledLanguage( &it ) {
            result.append( String( cString: opt ) )
        }
    }
    
    return result
}


/******************************************************************************
 ** Convenience Methods
 **************************************************************************** */
// MARK: - Private:

/**
 Returns an array of everything that could have been passed to the
 ConfigCallback, where the key indicates the unrecognized configuration option
 and the value indicating the proposed value. This convenience method avoids 
 having to use your own callback to collect this data.
 @TODO: provide a function that can set a USER's struct or array that
   conforms to the protocol, instead of specifying our own sample class.
*/
public func tidyConfigRecords( forTidyDoc: TidyDoc ) -> [TidyConfigReport] {
    
    guard
        let ptrStorage = CLibTidy.tidyGetAppData( forTidyDoc )
    else { return [] }
    
    let storage = Unmanaged<ApplicationData>
        .fromOpaque(ptrStorage)
        .takeUnretainedValue()

    return storage.configCallbackRecords
}

/******************************************************************************
 ** Private Stuff
 **************************************************************************** */
// MARK: - Private:


/**
 An instance of this class is retained by CLibTidy's AppData, and is used to
 store additional pointers that we cannot store in CLibTidy directly.
 - appData: Contains the pointer used by `tidySetAppData()`.
 - configCallback: Contains the pointer used by `tidySetConfigCallback()`.
 - tidyMessageCallback: Contains the pointer used by `tidySetMessageCallback`.
*/
private class ApplicationData {
    var appData: AnyObject?
    var configCallback: TidyConfigCallback?
    var configCallbackRecords: [TidyConfigReport]
    var tidyMessageCallback: TidyMessageCallback?
    var tidyMessageCallbackRecords: [[ String : String ]]
    var tidyPPCallback: TidyPPProgress?
    var tidyPPCallbackRecords: [[ String : String ]]
    
    init() {
        self.appData = nil
        self.configCallback = nil
        self.configCallbackRecords = []
        self.tidyMessageCallback = nil
        self.tidyMessageCallbackRecords = []
        self.tidyPPCallback = nil
        self.tidyPPCallbackRecords = []
    }
}
