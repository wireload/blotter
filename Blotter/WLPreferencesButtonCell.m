//
//  WLPreferencesButtonCell.m
//  Blotter
//
//  Created by Alexander Ljungberg on 31.03.11.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLPreferencesButtonCell.h"


@implementation WLPreferencesButtonCell

#pragma mark Methods

- (BOOL)isTall:(NSRect)cellFrame
{
    return cellFrame.size.height == 50.0;
}

- (NSBezierPath *)focusRingShapeForCellFrame:(NSRect)aCellFrame
{
    NSRect outlineFrame = aCellFrame;
    // Ignore bottom 1px of shadow.
    outlineFrame.size.height -= 1;
    outlineFrame = NSInsetRect(outlineFrame, 1.0, 1.0);
    return [NSBezierPath bezierPathWithRoundedRect:outlineFrame xRadius:4 yRadius:4];
}


#pragma mark NSCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (![self isTall:cellFrame])
    {
        float alpha = [self isEnabled] ? 1.0 : 0.75;

        if (![self isHighlighted])
        {
            NSDrawThreePartImage(cellFrame,
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-left"],
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-centre"],
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }
        else
        {
            NSDrawThreePartImage(cellFrame,
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-active-left"],
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-active-centre"],
                                 [NSImage imageNamed:@"preferences-about-blotter-button-bezel-active-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }

        NSRect titleFrame = [self titleRectForBounds:cellFrame];
        NSRect imageFrame = [self imageRectForBounds:cellFrame];

        [self drawTitle:[self attributedTitle] withFrame:titleFrame inView:controlView];

        [self drawImage:[self image] withFrame:imageFrame inView:controlView];
    }
    else
    {
        float alpha = [self isEnabled] ? 1.0 : 0.75;

        if (![self isHighlighted])
        {
            NSDrawThreePartImage(cellFrame,
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-left"],
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-centre"],
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }
        else
        {
            NSDrawThreePartImage(cellFrame,
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-active-left"],
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-active-centre"],
                                 [NSImage imageNamed:@"preferences-about-blotter-tall-button-bezel-active-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }

        NSRect titleFrame = [self titleRectForBounds:cellFrame];
        NSRect imageFrame = [self imageRectForBounds:cellFrame];
        // Our custom "rate this" button needs the vertical alignment of its text and label tweaked.
        titleFrame.origin.y += 2;
        imageFrame.origin.y -= 2;

        [self drawTitle:[self attributedTitle] withFrame:titleFrame inView:controlView];
        [self drawImage:[self image] withFrame:imageFrame inView:controlView];
    }
}

- (NSRect)imageRectForBounds:(NSRect)theRect
{
    if ([self image] != nil && [self imagePosition] == NSImageLeft)
    {
        // Prevent image from being cut off on the top or bottom and position it better than the default.
        NSSize size = [[self image] size];
        return NSMakeRect(14.0, floor((theRect.size.height - size.height) / 2.0), size.width, size.height);
    }

    return [super imageRectForBounds:theRect];
}

- (void)drawFocusRingMaskWithFrame:(NSRect)aCellFrame inView:(NSView *)aControlView
{
    [[self focusRingShapeForCellFrame:aCellFrame] fill];
}

@end
