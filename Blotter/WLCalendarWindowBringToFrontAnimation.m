//
//  WLCalendarWindowBringToFrontAnimation.m
//  Blotter
//
//  Created by Ilya Kulakov on 09.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBringToFrontAnimation.h"


@implementation WLCalendarWindowBringToFrontAnimation

- (instancetype)initWithWindow:(WLCalendarWindow *)aWindow
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
    super.currentProgress = aProgress;
    _window.alphaValue = self.currentValue;
}

@end
