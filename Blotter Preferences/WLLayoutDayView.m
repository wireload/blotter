//
//  WLLayoutDayView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutDayView.h"


@implementation WLLayoutDayView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [[NSColor darkGrayColor] setFill];
    NSRectFill([self bounds]);
}

@end
