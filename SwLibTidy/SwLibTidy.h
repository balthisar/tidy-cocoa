#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double SwLibTidyVersionNumber;
FOUNDATION_EXPORT const unsigned char SwLibTidyVersionString[];

// Discussion: we want to export the symbols in tidyenum.h, so that users of
// SwLibTidy can use these symbols. For some reason, it's not good enough to
// include this file in *our own* source; we have to fetch it from CLibTidy,
// or some other module.
#import <CLibTidy/tidyenum.h>
