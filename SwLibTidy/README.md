# SwLibTidy

This directory:

- Defines a module for use with Xcode/Clang named `SwLibTidy`.
- Provides a direct implementation of CLibTidy using Swift native types.
- Provides an abstracted implementation of CLibTidy using Swift/Objective-C
  native types, and compatible with both Swift and Objective-C.


## Framework

`SwLibTidy` is intended to be used as a framework. While this complicates
console applications, it ensures that all of its resources can be bundled into
a single structure.

## Linking

`SwLibTidy` dynamically links to `libtidy-sw.dylib`, which is put into the
framework bundle where the dynamic linker will find it. Additionally the dynamic
linker will first search `/usr/local/lib`, so that end-user applications can
update their versions of Tidy if your provide instructions.

## Swift Libraries, Swift Applications, and Objective-C

Note that build settings include `SWIFT_FORCE_STATIC_LINK_STDLIB = YES`, which
will ensure that this framework, when built, includes the Swift standard
libraries statically linked. This is done to support console applications
written in Swift, which *must* use `SWIFT_FORCE_DYNAMIC_LINK_STDLIB = YES`
in their build settings in order to avoid duplicate symbol warnings.

If you are using additional libraries with Swift, you may want to fiddle with
this configuration setting.

Until Swift libraries are part of macOS proper, this is going to be a bit
hacky.
