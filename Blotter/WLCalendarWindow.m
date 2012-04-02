//
//  WLCalendarWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindow.h"
#import "WLCalendarWindowBackgroundView.h"
#import "NSColor+WLCalendar.h"


@interface _WLFlippedView : NSView
@end


@implementation _WLFlippedView

- (BOOL)isFlipped
{
    return YES;
}

@end


@implementation WLCalendarWindow

- (id)init
{
    self = [self initWithContentRect:NSZeroRect
                           styleMask:NSBorderlessWindowMask
                             backing:NSBackingStoreBuffered
                               defer:NO];
    if (self != nil)
    {
        [self setOpaque:NO];
        [self setAutorecalculatesKeyViewLoop:NO];
        [self setHasShadow:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setIgnoresMouseEvents:YES];
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            [self setLevel:kCGDesktopWindowLevel];
        else
        {
            // On Lion window level of desktop elements is kCGDesktopWindowLevel + 21.
            [self setLevel:kCGDesktopWindowLevel + 15];
        }
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [self setCanHide:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self useOptimizedDrawing:YES];
        [self setContentView:[[[_WLFlippedView alloc] init] autorelease]];
    }
    return self;
}


#pragma mark Methods

- (NSView *)realContentView
{
    return [super contentView];
}


#pragma mark NSWindow

- (NSRect)frameRectForContentRect:(NSRect)aWindowContentRect
{
    return [WLCalendarWindowBackgroundView frameRectForContentRect:aWindowContentRect];
}

- (NSRect)contentRectForFrameRect:(NSRect)aWindowFrame
{
    aWindowFrame.origin.x = 0;
    aWindowFrame.origin.y = 0;
    return [WLCalendarWindowBackgroundView contentRectForFrameRect:aWindowFrame];
}

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

- (void)setContentView:(NSView *)aView
{
    if (![_realContentView isEqualTo:aView])
    {
        NSRect bounds = [self frame];
        bounds.origin = NSZeroPoint;

        WLCalendarWindowBackgroundView *frameView = [super contentView];
        if (frameView == nil)
        {
            frameView = [[[WLCalendarWindowBackgroundView alloc] initWithFrame:bounds] autorelease];
            [super setContentView:frameView];
        }

        [_realContentView removeFromSuperview];
        _realContentView = aView;
        [_realContentView setFrame:[self contentRectForFrameRect:bounds]];
        [_realContentView setNeedsDisplay:YES];
        [frameView addSubview:_realContentView];
    }
}

- (id)contentView
{
    return _realContentView;
}

- (void)setLevel:(NSInteger)newLevel
{
    [super setLevel:newLevel];
    [[super contentView] setNeedsDisplay:YES];
}

@end
