/******************************************************************************

 SwLibTidyConsole.swift
 Console compatibility library for using SwLibTidy.

 Copyright © 2107 by HTACG. All rights reserved.
 Created by Jim Derry 2017; copyright assigned to HTACG. Permission to use
 this source code per the W3C Software Notice and License:
 https://www.w3.org/Consortium/Legal/2002/copyright-software-20021231

 Purpose
   Provide a known set of Swift Standard Libraries for console applications to
   link against. As Swift is still "experimental," it is not part of macOS or
   iOS proper; applications are expected to ship with the required Swift
   Standard Libraries within their bundle. Console applications are not within
   bundles, however.

   Xcode deals with this situation by statically linking the Swift Standard
   Libraries into the console application, but this makes it impossible for
   console applications to link cleanly against Swift libraries (which *must*
   be frameworks).

   This framework provides the required Swift Standard Library for console
   applications (Swift or Objective-C) to link against. Because it consists
   of nothing but import statements, ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES
   will ensure that all of the necessary Swift dylibs are present. Makes sure
   that your console applications do each of the following:

   - Include this framework as a Target Dependency.
   - Link Binary with Libraries, including this framework.
   - SWIFT_FORCE_DYNAMIC_LINK_STDLIB = YES
   - SWIFT_FORCE_STATIC_LINK_STDLIB = NO
   - LD_RUNPATH_SEARCH_PATHS = A complete path to the dylibs within this
       framework, as well as paths to your other frameworks.

 ******************************************************************************/

import Foundation
import Cocoa
import SwLibTidy
