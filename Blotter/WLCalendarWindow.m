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

@synthesize state;

static const CGFloat fadeDuration = 0.1;

- (int)finderLevel
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        return kCGDesktopWindowLevel;
    else
    {
        // On Lion window level of desktop elements is kCGDesktopWindowLevel + 21.
        return kCGDesktopWindowLevel + 15;
    }   
}

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
        [self setLevel:[self finderLevel]];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [self setCanHide:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self useOptimizedDrawing:YES];
        [self setContentView:[[[_WLFlippedView alloc] init] autorelease]];
        
        state = WLFinderLevelState;
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
    return state == WLFloatingLevelState;
}

- (BOOL)canBecomeMainWindow
{
    return state == WLFloatingLevelState;
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

- (void)setFinderLevel
{
    NSView *frameView = [super contentView];
    
    // NSDisableScreenUpdates();
    
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [self setLevel:[self finderLevel]];
    // If we went to Finder level due to becoming inactive during a space shift, then
    // we must also order to the front or we somehow end up underneath Finder.
    [self orderFrontRegardless];
    [frameView display];
    [self display];
    state = WLFinderLevelState;

    // NSEnableScreenUpdates();

    [CATransaction begin];
    [CATransaction setAnimationDuration:fadeDuration];
    [[frameView layer] setOpacity:1.0];
    [CATransaction commit];
}

- (void)setFloatingLevel
{
    NSView *frameView = [super contentView];

    //NSDisableScreenUpdates();

    [self setLevel:NSFloatingWindowLevel];
    [self setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    [frameView display];
    [self display];
    state = WLFloatingLevelState;   
    
    [NSApp activateIgnoringOtherApps:YES];
    [self makeKeyAndOrderFront:nil];

    //NSEnableScreenUpdates();

    [CATransaction begin];
    [CATransaction setAnimationDuration:fadeDuration];
    [[frameView layer] setOpacity:1.0];
    [CATransaction commit];
}

- (void)cancelOperation:(id)sender
{
    if (state != WLFinderLevelState)
        [self levelDown];
}

- (void)levelUp
{
    if (state != WLFloatingLevelState && state != WLLevelingUpState)
    {
        NSView *frameView = [super contentView];

        state = WLLevelingUpState;

        [CATransaction begin];
        [CATransaction setCompletionBlock:^(void) {
            if (state == WLLevelingUpState)
                [self setFloatingLevel];
        }];
        [CATransaction setAnimationDuration:fadeDuration];
        [[frameView layer] setOpacity:0.0];
        [CATransaction commit];
    }
}

- (void)levelDown
{
    if (state != WLFinderLevelState && state != WLLevelingDownState)
    {
        NSView *frameView = [super contentView];
        state = WLLevelingDownState;
        
        [CATransaction begin];
        [CATransaction setCompletionBlock:^(void) {
            if (state == WLLevelingDownState)
                [self setFinderLevel];
        }];
        [CATransaction setAnimationDuration:fadeDuration];
        [[frameView layer] setOpacity:0.0];
        [CATransaction commit];
    }    
}

@end
