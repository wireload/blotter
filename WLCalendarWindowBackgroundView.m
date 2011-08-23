//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowBackgroundView.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarWindowBackgroundView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.2] WL_CGColor];
        layer.borderColor = [[[NSColor blackColor] colorWithAlphaComponent:0.5f] WL_CGColor];
        layer.borderWidth = 10.0f;
        layer.cornerRadius = 10.0f;
        [self setLayer:layer];
        [self setWantsLayer:YES];
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

@end
