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


static const CGFloat _WLCalendarBackgroundActiveBlur = 4.0;


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
        [self setCanHide:NO];
        [self setDisplaysWhenScreenProfileChanges:YES];
        [self useOptimizedDrawing:YES];
        [self setContentView:[[[_WLFlippedView alloc] init] autorelease]];
        if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
            [self setAnimationBehavior:NSWindowAnimationBehaviorNone];

        // This filter will be responsible for flipping the input image upside down. It can't be
        // fully prepared in advance because we need to know the height of the image.
        CIFilter *transform = [CIFilter filterWithName:@"CIAffineTransform"];

        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:_WLCalendarBackgroundActiveBlur] forKey:@"inputRadius"];

        _blurInputFilter = [transform retain];
        _blurOutputFilter = [filter retain];
    }
    return self;
}

- (void)dealloc
{
    [_blurInputFilter release];
    [_blurOutputFilter release];
    [super dealloc];
}



#pragma mark Methods

- (WLCalendarWindowBackgroundView *)realContentView
{
    return [super contentView];
}

- (CGImageRef)newCGImageOfScreenBelowWindow
{
    BEGIN_TIMING();

    NSArray *screens = [NSScreen screens];
    if ([screens count] > 0)
    {
        NSScreen *screenWithMenubar = [screens objectAtIndex:0];
        NSRect windowFrame = [self frame];

        // Map window frame
        // FROM coordinates where both window and screen origins are bottom left and y-axis values increase upward
        // TO coordinates where both window and screen origins are top left and y-axis values increase downward.

        NSAffineTransform *windowOriginTransform = [NSAffineTransform transform];
        [windowOriginTransform translateXBy:0.0 yBy:NSHeight(windowFrame)];

        NSAffineTransform *screenOriginAndDirectionTransform = [NSAffineTransform transform];
        [screenOriginAndDirectionTransform translateXBy:0.0 yBy:NSHeight([screenWithMenubar frame])];
        [screenOriginAndDirectionTransform scaleXBy:1.0 yBy:-1.0];

        NSAffineTransform *resultTransform = [NSAffineTransform transform];
        [resultTransform appendTransform:windowOriginTransform];
        [resultTransform appendTransform:screenOriginAndDirectionTransform];
        windowFrame.origin = [resultTransform transformPoint:windowFrame.origin];

        CGWindowID windowId = (CGWindowID)[self windowNumber];
        CGImageRef desktopImage = CGWindowListCreateImage(NSRectToCGRect(windowFrame),
                                                          kCGWindowListOptionOnScreenBelowWindow,
                                                          windowId,
                                                          kCGWindowImageBoundsIgnoreFraming);

        END_TIMING(@"capture background");

        return desktopImage;
    }
    else
        return NULL;
}

- (CIImage *)blurredBackgroundImage
{
    BEGIN_TIMING();
    CGImageRef backgroundImage = [self newCGImageOfScreenBelowWindow];
    CIImage *ciImage = [CIImage imageWithCGImage:backgroundImage];
    CGImageRelease(backgroundImage);

    // Flip image upside down.
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:0 yBy:[ciImage extent].size.height];
    [affineTransform scaleXBy:1.0 yBy:-1.0];

    [_blurInputFilter setValue:ciImage forKey:@"inputImage"];
    [_blurInputFilter setValue:affineTransform forKey:@"inputTransform"];
    [_blurOutputFilter setValue:[_blurInputFilter valueForKey:@"outputImage"] forKey:@"inputImage"];

    CIImage *result = [_blurOutputFilter valueForKey:@"outputImage"];

    END_TIMING(@"blur background");

    return result;
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
