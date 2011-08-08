//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBackgroundView.h"


@implementation WLCalendarWindowBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] setFill];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

@end
