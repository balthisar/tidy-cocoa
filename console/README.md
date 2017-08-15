# Console Application

The console application is just a simple demonstration of using SwLibTidy for
non-GUI applications. It is _not_ intended to become a replacement for the real
**HTML Tidy**, and is missing all of the features that make the official Tidy
an indispensible tool.

Note that this project is built _without_ the **SwLibTidy** framework proper.
Because console applications don’t have bundles, we would have to install a 
framework somewhere else on the end-user‘s computer.

Instead, this example statically links to the `tidy-html5` library target, and
compiles the `SwLibTidy.h` from the framework directly, resulting in a single,
binary executable file.

In the future when Swift’s Application Binary Interface (ABI) is complete, it
will be possible to generate static libraries that include Swift code, meaning
that we will be able to build a single framework that can be statically linked.
