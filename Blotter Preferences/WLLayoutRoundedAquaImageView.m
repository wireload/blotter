//
//  WLRoundedImageView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLLayoutRoundedAquaImageView.h"
#import "WLGraphics.h"


@implementation WLLayoutRoundedAquaImageView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        [self setWantsLayer:YES];
    }
    return self;
}


#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    NSRect imageFrame = [self bounds];
    // WLRecessedBoxShadow draws 1px horizontal white line at the bottom.
    imageFrame.origin.y += 1.0f;
    imageFrame.size.height -= 1.0f;
    [[NSBezierPath bezierPathWithRoundedRect:imageFrame
                                     xRadius:1.25f
                                     yRadius:1.25] addClip];
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForImageResource:@"Recreated-Aqua"];
    NSImage *img = [[NSImage alloc] initWithContentsOfURL:url];
    [img drawInRect:imageFrame
           fromRect:NSZeroRect
          operation:NSCompositeSourceOver
           fraction:1.0f];
    [img release];
    [NSGraphicsContext restoreGraphicsState];
    
    WLRecessedBoxShadow([self bounds]);
}

@end
