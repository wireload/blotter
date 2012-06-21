//
//  WLGlassHudButtonCell.m
//  Blotter
//
//  Created by Ilya Kulakov on 13.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WLGraphics.h>

#import "WLGlassHudButtonCell.h"


@implementation WLGlassHudButtonCell

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (![self isEnabled])
    {
        WLDrawScaledThreePartImage(cellFrame,
                             [NSImage imageNamed:@"glass-hud-button-disabled-left"],
                             [NSImage imageNamed:@"glass-hud-button-disabled-middle"],
                             [NSImage imageNamed:@"glass-hud-button-disabled-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    else if (![self isHighlighted])
    {
        WLDrawScaledThreePartImage(cellFrame,
                             [NSImage imageNamed:@"glass-hud-button-left"],
                             [NSImage imageNamed:@"glass-hud-button-middle"],
                             [NSImage imageNamed:@"glass-hud-button-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    else
    {
        WLDrawScaledThreePartImage(cellFrame,
                             [NSImage imageNamed:@"glass-hud-button-active-left"],
                             [NSImage imageNamed:@"glass-hud-button-active-middle"],
                             [NSImage imageNamed:@"glass-hud-button-active-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             NO);
    }
    // Title frame is the button frame without round parts and shadows.
    NSRect titleFrame = NSInsetRect(cellFrame, 7, 2);
    titleFrame.size.height -= 1;
    [self drawTitle:[self attributedTitle] withFrame:titleFrame inView:controlView];
    
    if ([self showsFirstResponder])
    {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRoundedRect:cellFrame xRadius:7 yRadius:9] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSMutableAttributedString *whiteTitle = [[title mutableCopy] autorelease];
    NSRange titleLength = NSMakeRange(0, [whiteTitle length]);
    [whiteTitle beginEditing];
    [whiteTitle addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Lucida Grande" size:11] range:titleLength];
    float titleAlpha = [self isEnabled] ? 1.0 : 0.85;
    [whiteTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedWhite:0.98 alpha:titleAlpha] range:titleLength];
    [whiteTitle endEditing];
    return [super drawTitle:whiteTitle withFrame:frame inView:controlView];
}

@end
