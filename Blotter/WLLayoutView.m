//
//  WLLayoutView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLLayoutView.h"
#import "NSColor+WLPrefColors.h"


static NSImage *Images[9];

static NSColor *Tile = nil;

static const CGFloat RoundRadius = 2.0;


@implementation WLLayoutView

#pragma mark NSView

- (void)viewWillDraw
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Images[0] = [NSImage imageNamed:@"preferences-layout-area-top-left"];
        Images[1] = [NSImage imageNamed:@"preferences-layout-area-top-centre"];
        Images[2] = [NSImage imageNamed:@"preferences-layout-area-top-right"];
        Images[3] = [NSImage imageNamed:@"preferences-layout-area-centre-left"];
        Images[4] = [NSImage imageNamed:@"preferences-layout-area-centre-centre"];
        Images[5] = [NSImage imageNamed:@"preferences-layout-area-centre-right"];
        Images[6] = [NSImage imageNamed:@"preferences-layout-area-bottom-left"];
        Images[7] = [NSImage imageNamed:@"preferences-layout-area-bottom-centre"];
        Images[8] = [NSImage imageNamed:@"preferences-layout-area-bottom-right"];
        Tile = [NSColor WL_layoutViewTileColor];
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
                        1.0,
                        YES);
    [NSGraphicsContext restoreGraphicsState];

    [NSGraphicsContext saveGraphicsState];
    NSRect tileFrame = NSInsetRect([self bounds], 2.0, 1.0);
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
