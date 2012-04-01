//
//  WLPreferencesButtonCell.m
//  Blotter
//
//  Created by Alexander Ljungberg on 31.03.11.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLPreferencesButtonCell.h"


@implementation WLPreferencesButtonCell

- (NSImage *)bundleImage:(NSString *)aName
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForImageResource:aName];
    return [[[NSImage alloc] initWithContentsOfURL:url] autorelease];    
}

- (BOOL)isTall:(NSRect)cellFrame
{
    return cellFrame.size.height == 50.0; 
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (![self isTall:cellFrame])
    {
        float alpha = [self isEnabled] ? 1.0 : 0.75;
        
        if (![self isHighlighted])
        {
            NSDrawThreePartImage(cellFrame,
                                 [self bundleImage:@"about-blotter-button-bezel-left"],
                                 [self bundleImage:@"about-blotter-button-bezel-centre"],
                                 [self bundleImage:@"about-blotter-button-bezel-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }
        else
        {
            NSDrawThreePartImage(cellFrame,
                                 [self bundleImage:@"about-blotter-button-bezel-active-left"],
                                 [self bundleImage:@"about-blotter-button-bezel-active-centre"],
                                 [self bundleImage:@"about-blotter-button-bezel-active-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }
        
        NSRect titleFrame = [self titleRectForBounds:cellFrame];
        NSRect imageFrame = [self imageRectForBounds:cellFrame];
        
        [self drawTitle:[self attributedTitle] withFrame:titleFrame inView:controlView];
        
        [self drawImage:[self image] withFrame:imageFrame inView:controlView];
        
        if ([self showsFirstResponder])
        {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            NSRect outlineFrame = cellFrame;
            // Ignore bottom 1px of shadow.
            outlineFrame.size.height -= 1;
            outlineFrame = NSInsetRect(outlineFrame, 1.0, 1.0);
            [[NSBezierPath bezierPathWithRoundedRect:outlineFrame xRadius:4 yRadius:4] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
    else 
    {
        float alpha = [self isEnabled] ? 1.0 : 0.75;

        if (![self isHighlighted])
        {
            NSDrawThreePartImage(cellFrame,
                                 [self bundleImage:@"about-blotter-tall-button-bezel-left"],
                                 [self bundleImage:@"about-blotter-tall-button-bezel-centre"],
                                 [self bundleImage:@"about-blotter-tall-button-bezel-right"],
                                 NO,
                                 NSCompositeSourceOver,
                                 alpha,
                                 YES);
        }
        else
        {
            NSDrawThreePartImage(cellFrame,
                                 [self bundleImage:@"about-blotter-tall-button-bezel-active-left"],
                                 [self bundleImage:@"about-blotter-tall-button-bezel-active-centre"],
                                 [self bundleImage:@"about-blotter-tall-button-bezel-active-right"],
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
        
        if ([self showsFirstResponder])
        {
            [NSGraphicsContext saveGraphicsState];
            NSSetFocusRingStyle(NSFocusRingOnly);
            NSRect outlineFrame = cellFrame;
            // Ignore bottom 1px of shadow.
            outlineFrame.size.height -= 1;
            outlineFrame = NSInsetRect(outlineFrame, 1.0, 1.0);
            [[NSBezierPath bezierPathWithRoundedRect:outlineFrame xRadius:4 yRadius:4] fill];
            [NSGraphicsContext restoreGraphicsState];
        }
    }
}

- (NSRect)imageRectForBounds:(NSRect)theRect
{
    if ([self image] != nil && [self imagePosition] == NSImageLeft)
    {
        // Prevent image from being cut off on the top or bottom and position it better than the default.
        NSSize size = [[self image] size];
        return NSMakeRect(14.0, floorf((theRect.size.height - size.height) / 2.0), size.width, size.height);
    }
    
    return [super imageRectForBounds:theRect];
}

@end
