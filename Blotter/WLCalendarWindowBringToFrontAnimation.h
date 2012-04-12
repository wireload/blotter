//
//  WLCalendarWindowBringToFrontAnimation.h
//  Blotter
//
//  Created by Ilya Kulakov on 09.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"


/*!
 @abstract  Animates change of window's alpha value.
 */
@interface WLCalendarWindowBringToFrontAnimation : NSAnimation
{
    WLCalendarWindow *_window;
}

/*!
 @param aWindow A Window which alpha value will be animated. Is not retained!
 */
- (id)initWithWindow:(WLCalendarWindow *)aWindow ;

@end
