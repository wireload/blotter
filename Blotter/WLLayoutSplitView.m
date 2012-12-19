//
//  WLLayoutSplitView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLLayoutSplitView.h"
#import "NSColor+WLPrefColors.h"


@implementation WLLayoutSplitView

- (NSObject<WLLayoutSplitViewDelegate> *)delegate
{
    return (NSObject<WLLayoutSplitViewDelegate> *)[super delegate];
}

- (void)setDelegate:(NSObject <WLLayoutSplitViewDelegate> *)delegate
{
    [super setDelegate:delegate];
}


#pragma mark NSSplitView

- (void)drawDividerInRect:(NSRect)aRect
{
    static const CGFloat DotWidth = 3.0f;
    static const CGFloat DotSpace = 6.0f;

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetFillColorWithColor(context, [[NSColor WL_dotColor] WL_CGColor]);
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 0.0, [[NSColor WL_dotShadowColor] WL_CGColor]);

    if ([self isVertical])
    {
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f - DotSpace,
                                                       DotWidth,
                                                       DotWidth));
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f,
                                                       DotWidth,
                                                       DotWidth));
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f + DotSpace,
                                                       DotWidth,
                                                       DotWidth));
    }
    else
    {
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f - DotSpace,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f,
                                                       DotWidth,
                                                       DotWidth));
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f,
                                                       DotWidth,
                                                       DotWidth));
        CGContextFillEllipseInRect(context, CGRectMake(NSMinX(aRect) + (NSWidth(aRect) - DotWidth) / 2.0f + DotSpace,
                                                       NSMinY(aRect) + (NSHeight(aRect) - DotWidth) / 2.0f,
                                                       DotWidth,
                                                       DotWidth));
    }
}


#pragma mark NSView

- (void)mouseDown:(NSEvent *)anEvent
{
    if ([[self delegate] respondsToSelector:@selector(splitViewWillTrackMouse:)])
        [[self delegate] splitViewWillTrackMouse:self];
    [super mouseDown:anEvent];
    if ([[self delegate] respondsToSelector:@selector(splitViewDidTrackMouse:)])
        [[self delegate] splitViewDidTrackMouse:self];
}

@end
