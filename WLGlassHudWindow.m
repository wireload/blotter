//
//  WLGlassHudWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "WLGlassHudWindow.h"
#import "WLGlassHudView.h"
#import "WLGlassHudTextView.h"


BOOL _WLIsEventContainShortcut(NSEvent *event, NSUInteger shortcutFlags, int shortcutKey)
{
    static NSUInteger FlagsMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;

    NSUInteger eventFlags = [event modifierFlags];
    NSUInteger eventKeyCode = [event keyCode];

    return (eventFlags & (FlagsMask ^ shortcutFlags)) == 0 && (eventFlags & shortcutFlags) && eventKeyCode == shortcutKey;
}


@implementation WLGlassHudWindow

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:contentRect
                            styleMask:NSBorderlessWindowMask
                              backing:bufferingType
                                defer:deferCreation];
    if (self)
    {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
    }
    return self;
}

- (BOOL)makeFirstResponder:(NSResponder *)responder
{
    BOOL result = [super makeFirstResponder:responder];
    if (result
        && ![responder isEqual:_lastControl]
        && ([responder respondsToSelector:@selector(setDrawsBackground:)] || [responder respondsToSelector:@selector(setBezeled:)]))
    {
        if ([_lastControl respondsToSelector:@selector(setDrawsBackground:)])
            [_lastControl setDrawsBackground:NO];
        if ([_lastControl respondsToSelector:@selector(setBezeled:)])
            [_lastControl setBezeled:NO];
        _lastControl = responder;
        if ([_lastControl respondsToSelector:@selector(setDrawsBackground:)])
            [_lastControl setDrawsBackground:YES];
        if ([_lastControl respondsToSelector:@selector(setBezeled:)])
            [_lastControl setBezeled:YES];
    }
    return result;
}

- (NSRect)contentRectForFrameRect:(NSRect)windowFrame
{
    return windowFrame;
}

+ (NSRect)frameRectForContentRect:(NSRect)windowContentRect styleMask:(NSUInteger)windowStyle
{
	return windowContentRect;
}

- (void)setContentView:(NSView *)aView
{
    if (![_realContentView isEqualTo:aView])
    {
        NSRect bounds = [self frame];
        bounds.origin = NSZeroPoint;

        WLGlassHudView *frameView = [super contentView];
        if (frameView == nil)
        {
            frameView = [[[WLGlassHudView alloc] initWithFrame:bounds] autorelease];
            [super setContentView:frameView];
        }

        if (_realContentView != nil)
            [_realContentView removeFromSuperview];

        _realContentView = aView;

        for (id view in [aView subviews])
        {
            if ([view respondsToSelector:@selector(setBezeled:)])
                [view setBezeled:NO];
            if ([view respondsToSelector:@selector(setDrawsBackground:)])
                [view setDrawsBackground:NO];

        }

        [_realContentView setFrame:[self contentRectForFrameRect:bounds]];
        [_realContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [frameView addSubview:_realContentView];
    }
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

- (BOOL)canBecomeMainWindow
{
	return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask, kVK_ANSI_A))
    {
        [[self firstResponder] selectAll:self];
        return YES;
    }
    // Cut/Copy/Paste
    else if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask, kVK_ANSI_X))
    {
        id firstResponder = [self firstResponder];
        if ([firstResponder respondsToSelector:@selector(cut:)])
        {
            [firstResponder cut:self];
            return YES;
        }
    }
    else if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask, kVK_ANSI_C))
    {
        id firstResponder = [self firstResponder];
        if ([firstResponder respondsToSelector:@selector(copy:)])
        {
            [firstResponder copy:self];
            return YES;
        }
    }
    else if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask, kVK_ANSI_V))
    {
        id firstResponder = [self firstResponder];
        if ([firstResponder respondsToSelector:@selector(paste:)])
        {
            [firstResponder paste:self];
            return YES;
        }
    }
    // Undo/Redo
    else if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask, kVK_ANSI_Z))
    {
        [[[self firstResponder] undoManager] undo];
        return YES;
    }
    else if (_WLIsEventContainShortcut(theEvent, NSCommandKeyMask | NSShiftKeyMask, kVK_ANSI_Z))
    {
        [[[self firstResponder] undoManager] redo];
        return YES;
    }
    return NO;
}

@end
