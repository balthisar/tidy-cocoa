# TidyKit

This directory:

- Defines a module for use with Xcode/Clang named `TidyKit`.
- Provides protocols and default implementations of `SwLibTidy` as a protocol-
  oriented set of parts.
- Is compatible with Objective-C, unlike `SwLibTidy` that consists of top level
  functions and non-Objective-C-compatible protocols.


## Framework

`TidyKit` is intended to be used as a static framework. It has no resources, and
makes it simple to bind to console applications.


## SwLibTidy Linking

This framework does not link to a built version of `SwLibTidy`. The `SwLibTidy`
source is included in the build target, and comprises a fundamental part of
`TidyKit`.
