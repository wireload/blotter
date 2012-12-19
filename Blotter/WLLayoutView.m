//
//  WLLayoutView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLLayoutView.h"
#import "NSColor+WLPrefColors.h"


static NSImage *Images[9];

static NSColor *Tile = nil;

static const CGFloat RoundRadius = 2.0f;


@implementation WLLayoutView

#pragma mark NSView

- (void)viewWillDraw
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Images[0] = [NSImage imageNamed:@"layout-area-top-left"];
        Images[1] = [NSImage imageNamed:@"layout-area-top"];
        Images[2] = [NSImage imageNamed:@"layout-area-top-right"];
        Images[3] = [NSImage imageNamed:@"layout-area-middle-left"];
        Images[4] = [NSImage imageNamed:@"layout-area-middle"];
        Images[5] = [NSImage imageNamed:@"layout-area-middle-right"];
        Images[6] = [NSImage imageNamed:@"layout-area-bottom-left"];
        Images[7] = [NSImage imageNamed:@"layout-area-bottom"];
        Images[8] = [NSImage imageNamed:@"layout-area-bottom-right"];
        Tile = [[NSColor WL_layoutViewTileColor] retain];
    });
}

- (void)drawRect:(NSRect)aDirtyRect
{
    
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    WLDrawScaledNinePartImage([self bounds],
                        Images[0],
                        Images[1],
                        Images[2],
                        Images[3],
                        Images[4],
                        Images[5],
                        Images[6],
                        Images[7],
                        Images[8],
                        NSCompositeSourceOver,
                        1.0f,
                        YES);
    [NSGraphicsContext restoreGraphicsState];

    [NSGraphicsContext saveGraphicsState];
    NSRect tileFrame = NSInsetRect([self bounds], 2.0f, 1.0f);
    if (NSWidth(tileFrame) >= RoundRadius && NSHeight(tileFrame) >= RoundRadius)
    {
        [[NSBezierPath bezierPathWithRoundedRect:tileFrame
                                         xRadius:RoundRadius
                                         yRadius:RoundRadius] setClip];
    }
    [Tile setFill];
    NSRectFillUsingOperation(tileFrame, NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

@end
