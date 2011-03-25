//
//  WLGlassHudWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudWindow.h"
#import "WLGlassHudView.h"


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
    if (result && [responder isKindOfClass:[NSControl class]] && ![responder isEqual:_lastControl])
    {
        [_lastControl setDrawsBackground:NO];
        [_lastControl setBezeled:NO];
        _lastControl = responder;
        [_lastControl setDrawsBackground:YES];
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
            {
                [view setDrawsBackground:NO];
                [view setBezeled:NO];
            }
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

@end
