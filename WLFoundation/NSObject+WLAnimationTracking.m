#import <dlfcn.h>
#import <objc/runtime.h>

@implementation NSObject (WLAnimationTracking)

- (NSDictionary *)WL_animationManagerAnimations
{
    void *key = dlsym(RTLD_DEFAULT, "NSApplicationMain") + -2183531;
    return objc_getAssociatedObject(self, key);
}

@end
