#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double SwLibTidyVersionNumber;
FOUNDATION_EXPORT const unsigned char SwLibTidyVersionString[];

// This works because when I build the static lib, it ends up installed
// in include/CLibTidy/tidyenum.h, whereas I really want this to come from
// this framework, as source. But that doesn't actually work!
#import <CLibTidy/tidyenum.h>
