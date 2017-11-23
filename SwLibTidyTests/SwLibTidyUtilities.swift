//
//  SwLibTidyUtilities.swift
//  Swift LibTidy Tests
//
//  Created by Jim Derry on 11/20/17.
//  Copyright © 2017 Jim Derry. All rights reserved.
//

import Foundation
import SwLibTidy


/**
 Shuffles the contents of this collection.
 Contributed by Nate Cook from Stack Overflow.
 */
extension MutableCollection {

    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}


/**
 Returns an array with the contents of this sequence, shuffled.
 Contributed by Nate Cook from Stack Overflow.
 */
extension Sequence {

    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}


/*
 Returns x random words in an optional array of string. The words are provided
 by macOS in /usr/share/dict/words, and we will return nil if this can't be
 loaded.
 */
public func random_words( _ x: Int ) -> [String]? {

    guard
        let wordsString = try? String(contentsOfFile: "/usr/share/dict/words")
    else { return nil }

    let words = wordsString.components(separatedBy: .newlines)
    var result: [String] = [];

    for _ in 1...x {
        result.append( words[Int( arc4random_uniform( UInt32(words.count) ) )] )
    }

    return result;
}


/*
 Returns a string with a random doctype from the doctypes that Tidy recognizes.
 */
public func random_doctype() -> String {

    let words = [ "html5", "omit", "auto", "strict", "transitional" ];

    return words[ Int( arc4random_uniform( UInt32(words.count) ) ) ]
}


/*
 Returns an array of x random strings for use with the `mute` option. These
 are from CLibTidy `tidyenum.h`, defined in the `FOREACH_REPORT_MSG` macro.
 The test is fragile if CLibTidy removes any of these strings.
 */
public func random_mute( _ x: Int ) -> [String] {

    let words = [ "ADDED_MISSING_CHARSET",
                  "ANCHOR_NOT_UNIQUE",
                  "APOS_UNDEFINED",
                  "ATTR_VALUE_NOT_LCASE",
                  "ATTRIBUTE_IS_NOT_ALLOWED",
                  "ATTRIBUTE_VALUE_REPLACED",
                  "BACKSLASH_IN_URI",
                  "BAD_ATTRIBUTE_VALUE_REPLACED",
                  "BAD_ATTRIBUTE_VALUE",
                  "BAD_CDATA_CONTENT",
                  "BAD_CDATA_CONTENT",
                  "BAD_SUMMARY_HTML5",
                  "BAD_SURROGATE_LEAD",
                  "BAD_SURROGATE_PAIR",
                  "BAD_SURROGATE_TAIL",
                  "CANT_BE_NESTED",
                  "COERCE_TO_ENDTAG",
                  "CONTENT_AFTER_BODY",
                  "CUSTOM_TAG_DETECTED",
                  "DISCARDING_UNEXPECTED",
                  "DOCTYPE_AFTER_TAGS",
                  "DUPLICATE_FRAMESET",
                  "ELEMENT_NOT_EMPTY",
                  "ELEMENT_VERS_MISMATCH_ERROR",
                  "ELEMENT_VERS_MISMATCH_WARN",
                  "ENCODING_MISMATCH",
                  "ESCAPED_ILLEGAL_URI",
                  "FILE_CANT_OPEN",
                  "FILE_CANT_OPEN_CFG",
                  "FILE_NOT_FILE",
                  "FIXED_BACKSLASH",
                  "FOUND_STYLE_IN_BODY",
                  "ID_NAME_MISMATCH",
                  "ILLEGAL_NESTING",
                  "ILLEGAL_URI_CODEPOINT",
                  "ILLEGAL_URI_REFERENCE",
                  "INSERTING_AUTO_ATTRIBUTE",
                  "INSERTING_TAG",
                  "INVALID_ATTRIBUTE",
                  "INVALID_NCR",
                  "INVALID_SGML_CHARS",
                  "INVALID_UTF8",
                  "INVALID_UTF16",
                  "INVALID_XML_ID",
                  "JOINING_ATTRIBUTE",
                  "MALFORMED_COMMENT",
                  "MALFORMED_COMMENT_DROPPING",
                  "MALFORMED_COMMENT_EOS",
                  "MALFORMED_COMMENT_WARN",
                  "MALFORMED_DOCTYPE",
                  "MISMATCHED_ATTRIBUTE_ERROR",
                  "MISMATCHED_ATTRIBUTE_WARN",
                  "MISSING_ATTR_VALUE",
                  "MISSING_ATTRIBUTE",
                  "MISSING_DOCTYPE",
                  "MISSING_ENDTAG_BEFORE",
                  "MISSING_ENDTAG_FOR",
                  "MISSING_ENDTAG_OPTIONAL",
                  "MISSING_IMAGEMAP",
                  "MISSING_QUOTEMARK",
                  "MISSING_QUOTEMARK_OPEN",
                  "MISSING_SEMICOLON_NCR",
                  "MISSING_SEMICOLON",
                  "MISSING_STARTTAG",
                  "MISSING_TITLE_ELEMENT",
                  "MOVED_STYLE_TO_HEAD",
                  "NESTED_EMPHASIS",
                  "NESTED_QUOTATION",
                  "NEWLINE_IN_URI",
                  "NOFRAMES_CONTENT",
                  "NON_MATCHING_ENDTAG",
                  "OBSOLETE_ELEMENT",
                  "OPTION_REMOVED",
                  "OPTION_REMOVED_APPLIED",
                  "OPTION_REMOVED_UNAPPLIED",
                  "PREVIOUS_LOCATION",
                  "PROPRIETARY_ATTR_VALUE",
                  "PROPRIETARY_ATTRIBUTE",
                  "PROPRIETARY_ELEMENT",
                  "REMOVED_HTML5",
                  "REPEATED_ATTRIBUTE",
                  "REPLACING_ELEMENT",
                  "REPLACING_UNEX_ELEMENT",
                  "SPACE_PRECEDING_XMLDECL",
                  "STRING_CONTENT_LOOKS",
                  "STRING_ARGUMENT_BAD",
                  "STRING_DOCTYPE_GIVEN",
                  "STRING_MISSING_MALFORMED",
                  "STRING_MUTING_TYPE",
                  "STRING_NO_SYSID",
                  "STRING_UNKNOWN_OPTION",
                  "SUSPECTED_MISSING_QUOTE",
                  "TAG_NOT_ALLOWED_IN",
                  "TOO_MANY_ELEMENTS_IN",
                  "TOO_MANY_ELEMENTS",
                  "TRIM_EMPTY_ELEMENT",
                  "UNESCAPED_AMPERSAND",
                  "UNEXPECTED_END_OF_FILE_ATTR",
                  "UNEXPECTED_END_OF_FILE",
                  "UNEXPECTED_ENDTAG_ERR",
                  "UNEXPECTED_ENDTAG_IN",
                  "UNEXPECTED_ENDTAG",
                  "UNEXPECTED_EQUALSIGN",
                  "UNEXPECTED_GT",
                  "UNEXPECTED_QUOTEMARK",
                  "UNKNOWN_ELEMENT_LOOKS_CUSTOM",
                  "UNKNOWN_ELEMENT",
                  "UNKNOWN_ENTITY",
                  "USING_BR_INPLACE_OF",
                  "VENDOR_SPECIFIC_CHARS",
                  "WHITE_IN_URI",
                  "XML_DECLARATION_DETECTED",
                  "XML_ID_SYNTAX"
    ]

    var result: [String] = [];

    for _ in 1...x {
        result.append( words[Int( arc4random_uniform( UInt32(words.count) ) )] );
    }

    return result
}


/**
 An alternate implementation of the `TidyConfigReportProtocol`, which we will
 use for testing setTidyConfigRecords(forTidyDoc:toClass:).
 */
@objc public class JimsTidyConfigReport: NSObject, TidyConfigReportProtocol {

    public var option: String = ""
    public var value: String = ""

    public required init(withValue: String, forOption: String) {

        option = forOption;
        value = "---\(withValue)---";
        super.init()
    }
}



