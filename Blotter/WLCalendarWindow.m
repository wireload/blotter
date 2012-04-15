//
//  WLCalendarWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindow.h"
#import "NSColor+WLCalendar.h"
#import "WLCalendarWindowController.h"


@interface _WLFlippedView : NSView
@end


@implementation _WLFlippedView

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [self setWantsLayer:YES];
    }
    return self;
}

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
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [self setCanHide:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self useOptimizedDrawing:YES];
        [self setContentView:[[[_WLFlippedView alloc] init] autorelease]];
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
            [self setAnimationBehavior:NSWindowAnimationBehaviorNone];
    }
    return self;
}


#pragma mark Methods

- (WLCalendarWindowBackgroundView *)realContentView
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
    if ([[self windowController] respondsToSelector:@selector(windowState)])
        return [[self windowController] windowState] == WLFloatingLevelState;
    else
        return NO;
}

- (BOOL)canBecomeMainWindow
{
    if ([[self windowController] respondsToSelector:@selector(windowState)])
        return [[self windowController] windowState] == WLFloatingLevelState;
    else
        return NO;
}

- (NSView *)contentView
{
    return _fakeContentView;
}

- (void)setContentView:(NSView *)aView
{
    if (![_fakeContentView isEqualTo:aView])
    {
        NSRect bounds = [self frame];
        bounds.origin = NSZeroPoint;

        WLCalendarWindowBackgroundView *frameView = [super contentView];
        if (frameView == nil)
        {
            frameView = [[[WLCalendarWindowBackgroundView alloc] initWithFrame:bounds] autorelease];
            [super setContentView:frameView];
        }

        [_fakeContentView removeFromSuperview];
        _fakeContentView = aView;
        [_fakeContentView setFrame:[self contentRectForFrameRect:bounds]];
        [_fakeContentView setNeedsDisplay:YES];
        [frameView addSubview:_fakeContentView];
    }
}

- (void)cancelOperation:(id)aSender
{
    if ([[NSApp delegate] respondsToSelector:@selector(cancelOperation:)])
        [[NSApp delegate] cancelOperation:aSender];
    else
        [super cancelOperation:aSender];
}

@end
