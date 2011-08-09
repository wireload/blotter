//
//  WLCalendarWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindow.h"
#import "WLCalendarWindowBackgroundView.h"


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
        WLCalendarWindowBackgroundView *backgroundView = [[WLCalendarWindowBackgroundView alloc] init];
        [backgroundView setPostsFrameChangedNotifications:YES];
        [self setContentView:backgroundView];
        [backgroundView release];
    }
    return self;
}

- (NSRect)contentViewBounds
{
    CGFloat borderWidth = [[self contentView] layer].borderWidth;
    return NSInsetRect([[self contentView] bounds], borderWidth, borderWidth);
}

#pragma mark NSWindow

- (BOOL)canBecomeKeyWindow
{
    return NO;
}

- (BOOL)canBecomeMainWindow
{
    return NO;
}

@end
