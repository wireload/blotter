#import <AppKit/AppKit.h>


@interface NSObject (WLAnimationTracking)

/*!
 Animations currently in progress under NSAnimationManager's control.
 
 @discussion
 Current implementation works only against AppKit version present at compile time.
*/
- (nullable NSDictionary<NSString *, CAAnimation *> *)WL_animationManagerAnimations;

@end
