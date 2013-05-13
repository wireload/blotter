//
//  WLGlassHudPopUpButtonCell.m
//  Blotter
//
//  Created by Ilya Kulakov on 05.05.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLGlassHudPopUpButtonCell.h"


@implementation WLGlassHudPopUpButtonCell

- (NSAttributedString *)attributedTitle
{
    NSMutableAttributedString *attributedTitle = [[super attributedTitle] mutableCopy];
    [attributedTitle addAttributes:@{ NSForegroundColorAttributeName: [NSColor whiteColor] }
                             range:NSMakeRange(0, [attributedTitle length])];
    return attributedTitle;
}

- (void)drawBorderAndBackgroundWithFrame:(NSRect)aCellFrame inView:(NSView *)aControlView
{
    NSRect titleFrame = [self titleRectForBounds:aCellFrame];
    NSImage *arrows = [NSImage imageNamed:@"glass-hud-pop-up-button-arrows"];
    NSPoint arrowsLocation = NSMakePoint(ceil(fdim(NSMaxX(titleFrame) + (NSMaxX(aCellFrame) - NSMaxX(titleFrame)) / 2.0, [arrows size].width / 2.0)),
                                         ceil(fdim(NSMinY(aCellFrame) + (NSMaxY(aCellFrame) - NSMinY(aCellFrame)) / 2.0, [arrows size].height / 2.0)));
    [arrows drawAtPoint:arrowsLocation
               fromRect:NSZeroRect
              operation:NSCompositeSourceOver
               fraction:1.0];
    if ([self showsFirstResponder])
    {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        NSRect focusRingRect = NSMakeRect(NSMinX(titleFrame) - 2.0,
                                          NSMinY(titleFrame) - 1.0,
                                          NSWidth(titleFrame) + NSMaxX(aCellFrame) - NSMaxX(titleFrame) + 2.0,
                                          NSHeight(titleFrame) + 2.0);
        [[NSBezierPath bezierPathWithRoundedRect:focusRingRect
                                         xRadius:1
                                         yRadius:1] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

@end
