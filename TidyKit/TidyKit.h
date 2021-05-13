#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double TidyKitVersionNumber;
FOUNDATION_EXPORT const unsigned char TidyKitVersionString[];

// Discussion: we want to export the symbols in tidyenum.h, so that users of
// TidyKit can use these symbols. For some reason, it's not good enough to
// include this file in *our own* source; we have to fetch it from CLibTidy,
// or some other module.
#import <CLibTidy/tidyenum.h>
