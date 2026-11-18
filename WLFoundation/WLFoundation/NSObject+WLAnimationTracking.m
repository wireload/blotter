#import <WLFoundation/NSObject+WLAnimationTracking.h>


@implementation NSObject (WLAnimationTracking)

- (NSDictionary *)WL_animationManagerAnimations
{
    // NSAnimationManager keyed its associated object with a private AppKit symbol whose address used to be
    // resolved at build time by running nm against AppKit. Since macOS 11 system frameworks only exist in the
    // dyld shared cache, so the key can no longer be resolved and animation tracking is unavailable.
    return nil;
}

@end
