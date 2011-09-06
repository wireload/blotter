//
//  WLCalendarWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindow.h"
#import "WLCalendarWindowFrameView.h"


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
        [self setLevel:kCGDesktopWindowLevel];
        [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [self setCanHide:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self useOptimizedDrawing:YES];
        [self setContentView:[[[_WLFlippedView alloc] init] autorelease]];
    }
    return self;
}


#pragma mark NSWindow

+ (NSRect)frameRectForContentRect:(NSRect)windowContentRect styleMask:(NSUInteger)windowStyle
{
	return NSInsetRect(windowContentRect, [WLCalendarWindowFrameView borderWidth] + 10.0f, [WLCalendarWindowFrameView borderWidth] + 10.0f);
}

- (NSRect)contentRectForFrameRect:(NSRect)windowFrame
{
	return NSInsetRect(windowFrame, [WLCalendarWindowFrameView borderWidth] + 10.0f, [WLCalendarWindowFrameView borderWidth] + 10.0f);
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
