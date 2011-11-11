//
//  WLLayoutView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLLayoutView.h"


@implementation WLLayoutView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    static dispatch_once_t onceToken;
    static NSImage *Images[9];
    static NSColor *Tile = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        Images[0] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-top-left"]];
        Images[1] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-top"]];
        Images[2] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-top-right"]];
        Images[3] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-middle-left"]];
        Images[4] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-middle"]];
        Images[5] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-middle-right"]];
        Images[6] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-bottom-left"]];
        Images[7] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-bottom"]];
        Images[8] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-area-bottom-right"]];
        NSImage *pattern = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"layout-noise"]];
        Tile = [[NSColor colorWithPatternImage:pattern] retain];
        [pattern release];
    });
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    NSDrawNinePartImage([self bounds],
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
    [[NSBezierPath bezierPathWithRoundedRect:tileFrame
                                     xRadius:2.0f
                                     yRadius:2.0] addClip];
    [Tile setFill];
    NSRectFillUsingOperation(tileFrame, NSCompositeSourceOver);
    [NSGraphicsContext restoreGraphicsState];
}

- (BOOL)isFlipped
{
    return YES;
}

@end
