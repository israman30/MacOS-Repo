#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "netos-icon" asset catalog image resource.
static NSString * const ACImageNameNetosIcon AC_SWIFT_PRIVATE = @"netos-icon";

#undef AC_SWIFT_PRIVATE
