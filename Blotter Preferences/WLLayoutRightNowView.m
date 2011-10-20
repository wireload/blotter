//
//  WLLayoutRightNowView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutRightNowView.h"


@implementation WLLayoutRightNowView

#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor darkGrayColor] setFill];
    NSRectFill([self bounds]);
}

@end
