# CLibTidy

This directory:

- Contains the source code for Tidy HTML 5. As this is a Git submodule, it
  consists of the entire source distribution.
- Defines a module for use with Xcode/Clang named `CLibTidy`.
- Is used to build the target `tidy-sw`, resulting in `libtidy-sw.dylib`, which
  is required for `SwLibTidy`.


## Linking

`SwLibTidy` links to `libtidy-sw.dylib` dynamically. This separation between
between `SwLibTidy` and the dynamic library make it possible to use versions of
CLibTidy compiled elsewhere and installed in `/usr/local/lib/`, which is the
first place the dynamic linker looks. This means end users can upgrade the
Tidy version without having to wait for a new build.


## Build Notes

Building this target requires a custom build rule to process the `version.txt`
file provided by the upstream distribution. Thus this file must be included in
the target’s Target Membership. It will be “compiled” by the custom build
rule.

The custom build rule generates a C header file that is included into this
project via **Building Settings** -> **Prefix Header** for this target.
