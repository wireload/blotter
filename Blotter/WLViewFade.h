//
//  WLViewFade.h
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 @abstract Controls alpha value of a specific view.
 */
@interface WLViewFade : NSObject {
    NSTimer *_fadeOutTimer;
    NSView  *view;
}

@property (nonatomic, retain) NSView *view;

- (id)initWithView:(NSView *)aView;

/*!
 @abstract Forces view to fade in (if hidden). Invalidates timer.
 */
- (void)fadeIn;

/*!
 @abstract Schedules fade out timer if AudoFade is set.
 */
- (void)scheduleFadeOutTimer;

/*!
 @abstract Determines whether fade out timer is scheduled.
 */
- (BOOL)isFadeOutTimerScheduled;


- (void)_fadeOut;

@end
