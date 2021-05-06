# SwLibTidy

This directory:

- Defines a module for use with Xcode/Clang named `SwLibTidy`.
- Provides a direct implementation of CLibTidy using Swift native types.


## Framework

`SwLibTidy` is intended to be used as a static framework. Although there are
no resources, this makes it simple to use as a module and manage headers,
while being friendly to console applications that don't have bundles to install
frameworks.
