//
//  WLCalendarWindowBringToFrontAnimation.h
//  Blotter
//
//  Created by Ilya Kulakov on 09.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"


NS_ASSUME_NONNULL_BEGIN

/*!
    @brief  Animates change of window's alpha value.
*/
@interface WLCalendarWindowBringToFrontAnimation : NSAnimation

- (instancetype)initWithCoder:(NSCoder *)aCoder NS_UNAVAILABLE;

- (instancetype)initWithDuration:(NSTimeInterval)aDuration animationCurve:(NSAnimationCurve)anAnimationCurve NS_UNAVAILABLE;

/*!
    @param aWindow A Window which alpha value will be animated. Is not retained!
*/
- (instancetype)initWithWindow:(WLCalendarWindow *)aWindow NS_DESIGNATED_INITIALIZER;

@end


NS_ASSUME_NONNULL_END
