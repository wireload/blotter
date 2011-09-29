//
//  WLCalendarWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindow.h"
#import "WLCalendarWindowFrameView.h"
#import "NSColor+WLCalendar.h"


@interface _WLFlippedView : NSView
@end


@implementation _WLFlippedView

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)aDirtyRect
{
    [[NSColor WL_windowFrameBackgroundColor] set];
    NSRectFill([self bounds]);
}

@end


@implementation WLCalendarWindow

- (id)init
{
    self = [self initWithContentRect:NSMakeRect(0.0f, 0.0f, 0.0f, 0.0f)
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
	return NSInsetRect(aWindowContentRect,
                       -[WLCalendarWindowFrameView borderWidth],
                       -[WLCalendarWindowFrameView borderWidth]);
}

- (NSRect)contentRectForFrameRect:(NSRect)aWindowFrame
{
	return NSInsetRect(aWindowFrame,
                       [WLCalendarWindowFrameView borderWidth],
                       [WLCalendarWindowFrameView borderWidth]);
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

        WLCalendarWindowFrameView *frameView = [super contentView];
        if (frameView == nil)
        {
            frameView = [[[WLCalendarWindowFrameView alloc] initWithFrame:bounds] autorelease];
            [super setContentView:frameView];
        }

        [_realContentView removeFromSuperview];
        _realContentView = aView;
        [_realContentView setFrame:[self contentRectForFrameRect:bounds]];
        [_realContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [frameView addSubview:_realContentView];
    }
}

- (id)contentView
{
    return _realContentView;
}

@end
