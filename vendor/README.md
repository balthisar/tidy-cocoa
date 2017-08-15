# Vendor

## tidy-html5

The `tidy-html5` static library is linked to by **SwLibTidy** and by the sample
console application, where it is referred to as `CLibTidy`.

Note that building this target requires a custom build rule to process the
`version.txt` file provided by the upstream distribution. Thus this file must
be included in the target’s Target Membership.

The custom build rule generates a C header file that is included into this
project via Building Settings -> Prefix Header for this target.

In general the intention is to always use the upstream HTACG version of
HTML Tidy `next` branch; however temporarily (as of 15-August-2017) I am using
a custom version until I can push the changes back to `next`, in order to
implement the new `tidySetConfigCallback()` and deprecate
`tidySetOptionCallback()`.
