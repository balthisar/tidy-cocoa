# Important Swift Standard Library Linking Information

Note: Swift standard libraries are only part of macOS starting with 10.14.4,
meaning that if you want to support deployments prior to this, you’ll have
to think about linking strategies just a bit more.

Console applications typically statically link to the Swift library (i.e.,
the library becomes part of the excecutable, hence a 10 Mb "hello world")
Swift command line tool). Dynamic libraries and frameworks written in Swift also
need to link to the Swift standard libraries, but cannot dynamically link to
this embedded version, because the tool is an executable, not a dynamic library.
It has no symbols to export.

You might suppose you can accept static binding in the tool, and attempt dynamic
linking in the framework, but when the tool executes and the dynamic linker
loads your framework, duplicate symbols have now been introduced!

Therefore it’s obvious that we need to ensure that both the tool and the
framework link to a single instance of the library somehow, and there are a
few approaches to doing so until such time as Swift becomes part of the
operating system.


## Bundle Types

With bundle types (macOS and iOS application, XCTests, etc.), simply make sure
that `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` is **no** for all dependent
frameworks, and ensure that it’s **yes** for the host application. The build
system will ensure that all of the correct Swift dylibs are in the final bundle.


## Command Line Tools

The situation is kind of poor for command line tools, and you will be in
dependency and linker hell until the Swift Standard Library is part of macOS.
Therefore the sample command line tools in this package have been distributed
as bundles. If you choose this route for your own tools, simply create an
alias or symbolic link to the tool in the bundle, whereever you need it.

