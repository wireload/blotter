//
//  WLCalendarWindowBringToFrontAnimation.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBringToFrontAnimation.h"


@implementation WLCalendarWindowBringToFrontAnimation

- (id)initWithWindow:(WLCalendarWindow *)aWindow
{
    self = [super init];
    if (self != nil)
    {
        _window = aWindow;
    }
    return self;
}


#pragma mark NSAnimation

- (void)setCurrentProgress:(NSAnimationProgress)aProgress
{
    [super setCurrentProgress:aProgress];
    [_window setAlphaValue:[self currentValue]];
}

@end
