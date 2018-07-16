//
//  WLCalendarWindowBringToFrontAnimation.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBringToFrontAnimation.h"


@implementation WLCalendarWindowBringToFrontAnimation
{
    __weak WLCalendarWindow *_window;
}

- (instancetype)initWithWindow:(WLCalendarWindow *)aWindow
{
    if (self = [super initWithDuration:0.0 animationCurve:0])
        _window = aWindow;

    return self;
}


#pragma mark NSAnimation

- (void)setCurrentProgress:(NSAnimationProgress)aProgress
{
    super.currentProgress = aProgress;
    _window.alphaValue = self.currentValue;
}

@end
