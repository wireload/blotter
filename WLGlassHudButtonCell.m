//
//  WLGlassHudButtonCell.m
//  Blotter
//
//  Created by Ilya Kulakov on 13.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudButtonCell.h"


@implementation WLGlassHudButtonCell

-(void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSLog(@"State: %d", [self state]);
    if ([self isHighlighted] || [self state] == NSOffState)
    {
        NSDrawThreePartImage(cellFrame,
                             [NSImage imageNamed:@"glass-hud-button-left"],
                             [NSImage imageNamed:@"glass-hud-button-middle"],
                             [NSImage imageNamed:@"glass-hud-button-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             YES);
    }
    else {
        NSDrawThreePartImage(cellFrame,
                             [NSImage imageNamed:@"glass-hud-button-pressed-left"],
                             [NSImage imageNamed:@"glass-hud-button-pressed-middle"],
                             [NSImage imageNamed:@"glass-hud-button-pressed-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             YES);
    }

    [self drawTitle:[self attributedTitle] withFrame:cellFrame inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSMutableAttributedString *whiteTitle = [title mutableCopy];
    [whiteTitle beginEditing];
    [whiteTitle addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Lucida Grande" size:11] range:NSMakeRange(0, [whiteTitle length])];
    [whiteTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [whiteTitle length])];
    [whiteTitle endEditing];
    NSRect titleRect = [whiteTitle boundingRectWithSize:frame.size options:NSStringDrawingUsesLineFragmentOrigin];
    titleRect.origin.x += NSMidX(frame) - NSMidX(titleRect);
    titleRect.origin.y -= NSMidY(frame) - NSMidY(titleRect);
    [whiteTitle drawInRect:titleRect];
    [whiteTitle release];
    return titleRect;
}

@end
