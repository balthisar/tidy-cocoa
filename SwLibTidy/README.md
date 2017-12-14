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
update their versions of Tidy if you provide instructions.

