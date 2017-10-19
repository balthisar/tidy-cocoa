# Important Swift Standard Library Linking Information

Note that Swift standard libraries are _not_ part of macOS at the current time.
This means that all macOS Swift projects must link to the Swift standard
library somehow.

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

  - Any of…

    - Static bind the Swift standard library in the framework, or

    - Include the Swift standard library as dylibs in the Framework, or

    - Make another Framework that includes _only_ the Swift standard libraries.

  - Force the tool to use dynamic binding to the standard library instead of
    static binding the standard library, and tell the tool where to look.

  - Don’t link to the Swift libraries provided by Xcode!


## Three approaches…

### Static bind the Swift standard library in the framework

This approach builds the framework very much like a command line tool, in that
your framework’s dylib will include a copy of the Swift standard library built
into it, and because it's a dylib, all of the Swift library’s symbols will be
exported and available, too. Your tool, though, does need to know where to find
your framework, which it needs to do anyway in order to use the framework.

To ensure that the static binding takes place, ensure that
`ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES` (**Always Embed Swift Standard
Libraries**) is set to `NO` in your framework’s configuration, _and_ ensure
that you add a user-defined configuration `SWIFT_FORCE_STATIC_LINK_STDLIB`
set to `YES`.

Now, when your framework is built, its dylib will include the Swift standard
library and export its symbols.

This approach, though, can be fragile, because if you have multiple frameworks
that take the same approach, they will _all_ export the same Swift standard
library symbols, and the dynamic linker will complain about duplicate symbols
at runtime.

Don’t forget to configure the tool to search for your framework!


### Include the Swift standard library as dylibs in the Framework

In this case, Xcode will include the Swift standard libraries in your
framework’s **Frameworks/** directory, where it will be available for dynamic
linking from your own framework, as well as from your command line tool. You
will have to ensure that your `LD_RUNPATH_SEARCH_PATHS` (**Runpath Search
Paths**) in both the tool and the framework point to this directory, however.

To use this pattern, ensure that `ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES`
(**Always Embed Swift Standard Libraries**) is set to `YES` in your framework’s
configuration, _and_ ensure that the user-defined configuration
`SWIFT_FORCE_STATIC_LINK_STDLIB` is either missing, or set to `NO`.

A possible downside to this approach is that multiple frameworks may _also_ be
including the Swift standard libraries, and although duplicate symbols should
not be an issue, executable size will grow appreciably.


### Make another Framework that includes _only_ the Swift standard libraries

Very similar to the previos approach, but potentially aids in project
organization because you know exactly where the one, single instance of the
Swift standard libraries are, if you take steps to ensure that they’re not
present in your other libraries.

The biggest downside is that other frameworks have to know where to look to find
the standard libraries, rather than in their own **Frameworks/** directory, and
tools will need to install an additional framework into the installation
directory (what if every application developer installs a framework for this
purpose?).


## Force the tool to use dynamic binding to the standard library

To prevent the tool from embedding its own copy of the Swift standard library,
add `SWIFT_FORCE_DYNAMIC_LINK_STDLIB = YES` to your tool’s configuration,
and then set `LD_RUNPATH_SEARCH_PATHS` (**Runpath Search Paths**) to a location
that’s appropriate.

For example, if you are using the static approach in your framework, simply
ensure that you can access your framework, such as

~~~
@executable_path
~~~

The dynamic linker automatically searches `/Library/Frameworks/` and
`~/Library/Frameworks/` for you, and they do not have to be specified. The
example assumes your framework is in the same directory as your tool, such as
when building a tool with Xcode.

This automatic search fails when embedding the Swift standard libraries,
however. Instead, you'll have to specify something like like

~~~
@executable_path/SwLibTidy.framework/Versions/A/Frameworks
/Library/Frameworks/SwLibTidy.framework/Versions/A/Frameworks
~~~

…which is a lot more fragile.


## Objective-C and GUI/bundled applications

All of these approaches are compatible with Objective-C command line tools,
because Objective-C doesn’t require knowledge of the Swift libraries. In the
case of GUI applications (Objective-C or Swift), XCTests, and other bundles,
the general practice is to copy frameworks into the bundle, and so external
references in `LD_RUNPATH_SEARCH_PATHS` (**Runpath Search Paths**) become less
of an issue.

