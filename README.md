# SwLibTidy

## About

This Xcode project delivers the `SwLibTidy` framework for macOS development,
which is a native Swift wrapper for HTML Tidy (LibTidy). The main wrapper is
a purely procedural and mostly faithful wrapper of the C library, with native
Swift types and some convenient replacements, as well as a Swift-written,
Objective-C compatible set of protocols and classes for working in a more modern
manner.

## SwLibTidy

`SwLibTidy` proper is the procedural wrapper for `LibTidy` (referred to as
`CLibTidy` within this project). As it consists of Swift top-level functions,
this is not useful in Objective-C. In most cases, developers will prefer to use
the `TidyKit` and associated classes.

## TidyKit

wip…

