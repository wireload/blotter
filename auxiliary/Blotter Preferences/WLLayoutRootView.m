//
//  WLLayoutRootView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutRootView.h"


@implementation WLLayoutRootView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [[NSColor blackColor] setStroke];
    [[NSBezierPath bezierPathWithRect:[self bounds]] stroke];
}

@end
