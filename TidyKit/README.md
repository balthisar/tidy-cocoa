# TidyKit

This directory:

- Defines a module for use with Xcode/Clang named `TidyKit`.
- Provides protocols and default implementations of `SwLibTidy` as a protocol-
  oriented set of parts.


## Framework

`TidyKit` is intended to be used as a framework. While this complicates
console applications, it ensures that all of its resources can be bundled into
a single structure.

## Linking

`TidyKit` dynamically links to `libtidy-sw.dylib`, which is put into the
framework bundle where the dynamic linker will find it. Additionally the dynamic
linker will first search `/usr/local/lib`, so that end-user applications can
update their versions of Tidy if you provide instructions.

## SwLibTidy Linking

This framework does not link to a built version of `SwLibTidy`. The `SwLibTidy`
source is included in the build target, and comprises a fundamental part of
`TidyKit`.
