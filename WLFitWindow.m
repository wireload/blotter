//
//  WLFitWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLFitWindow.h"
#import "BLCalendarFramer.h"


@implementation WLFitWindow

- (void)update
{
    NSScreen *screen = [self screen];
    if (screen != nil)
        [self fitWithinFrame:[screen visibleFrame]];
    else
        NSLog(@"%@ is offscreen", self);
    [super update];
}

- (void)fitWithinFrame:(NSRect)aFrame
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger sizeSetting = [defaults integerForKey:@"CalendarSize"];
    int aPosition = MIN(BLPositionBottomRight, MAX(BLPositionTopLeft, [defaults integerForKey:@"CalendarPosition"]));
    
    NSRect desiredFrame = [BLCalendarFramer frameForPosition:(BLPosition) aPosition inFrame:aFrame size:sizeSetting];
    
    if (!NSEqualRects([self frame], desiredFrame))
    {
        NSLog(@"Placing at %@", NSStringFromRect(desiredFrame));
        [self setFrame:desiredFrame display:YES];
    }
}

@end
