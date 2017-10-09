# Vendor

## tidy-html5

The `tidy-html5` static library is linked to `SwLibTidy`, where it is referred 
to as `CLibTidy`.

Note that building this target requires a custom build rule to process the
`version.txt` file provided by the upstream distribution. Thus this file must
be included in the target’s Target Membership.

The custom build rule generates a C header file that is included into this
project via Building Settings -> Prefix Header for this target.
