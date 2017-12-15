/******************************************************************************

    TidyOptionProtocol.swift
    Part of the SwLibTidy wrapper library for tidy-html5 ("CLibTidy").
    See https://github.com/htacg/tidy-html5

    Copyright © 2107 by HTACG. All rights reserved.
    Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
    this source code per the W3C Software Notice and License:
    https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

    Purpose
      This protocol and class define and implement an object that is capable
      of handling Tidy's vast array of options.

    Audience
      Intended for use both when using SwLibTidy directly, as well as with
      protocol-based Tidy.

 ******************************************************************************/

import Foundation


/******************************************************************************
 Defines an interface for managing individual Tidy options.
 ******************************************************************************/
@objc public protocol TidyOptionProtocol: AnyObject {

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


}
