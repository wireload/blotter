//
//  WLCalendarWindowBackgroundView.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarWindowBackgroundView.h"

@implementation WLCalendarWindowBackgroundView

static const CGFloat WLCalendarBackgroundShadowTop = 6.0f;
static const CGFloat WLCalendarBackgroundShadowRight = 9.0f;
static const CGFloat WLCalendarBackgroundShadowBottom = 12.0f;
static const CGFloat WLCalendarBackgroundShadowLeft = 9.0f;
static const CGFloat WLCalendarBackgroundActiveBlur = 4.0;
static const CGFloat WLCalendarBackgroundActiveDarkness = 0.20;

#pragma mark Methods

+ (NSRect)glassRectForBounds:(NSRect)bounds
{
    NSRect glassRect = bounds;
    glassRect.origin.x += WLCalendarBackgroundShadowLeft + 3.0;
    glassRect.origin.y += WLCalendarBackgroundShadowTop + 3.0;
    glassRect.size.width -= WLCalendarBackgroundShadowLeft + 3.0 + WLCalendarBackgroundShadowRight + 3.0;
    glassRect.size.height -= WLCalendarBackgroundShadowTop + 3.0 + WLCalendarBackgroundShadowBottom + 3.0;    
    return glassRect;
}

+ (NSRect)contentRectForFrameRect:(NSRect)aFrame
{
    NSRect contentRect = [self glassRectForBounds:aFrame];
    return NSInsetRect(contentRect, 17.0, 17.0);
}

+ (NSRect)frameRectForContentRect:(NSRect)aContentRect
{
    NSRect frameRect = NSInsetRect(aContentRect, -17.0, -17.0);
    frameRect.origin.x -= WLCalendarBackgroundShadowLeft + 3.0;
    frameRect.origin.y -= WLCalendarBackgroundShadowTop + 3.0;
    frameRect.size.width += WLCalendarBackgroundShadowLeft + 3.0 + WLCalendarBackgroundShadowRight + 3.0;
    frameRect.size.height += WLCalendarBackgroundShadowTop + 3.0 + WLCalendarBackgroundShadowBottom + 3.0;    
    return frameRect;
}

+ (void)initialize
{
    [NSImage imageNamed:@"calendar-background-active-top-left"];
    [NSImage imageNamed:@"calendar-background-active-top-middle"];
    [NSImage imageNamed:@"calendar-background-active-top-right"];
    [NSImage imageNamed:@"calendar-background-active-middle-left"];
    [NSImage imageNamed:@"calendar-background-active-middle-middle"];
    [NSImage imageNamed:@"calendar-background-active-middle-right"];
    [NSImage imageNamed:@"calendar-background-active-bottom-left"];
    [NSImage imageNamed:@"calendar-background-active-bottom-middle"];
    [NSImage imageNamed:@"calendar-background-active-bottom-right"];

    [NSImage imageNamed:@"calendar-background-top-left"];
    [NSImage imageNamed:@"calendar-background-top-middle"];
    [NSImage imageNamed:@"calendar-background-top-right"];
    [NSImage imageNamed:@"calendar-background-middle-left"];
    [NSImage imageNamed:@"calendar-background-middle-middle"];
    [NSImage imageNamed:@"calendar-background-middle-right"];
    [NSImage imageNamed:@"calendar-background-bottom-left"];
    [NSImage imageNamed:@"calendar-background-bottom-middle"];
    [NSImage imageNamed:@"calendar-background-bottom-right"];
    
    [NSImage imageNamed:@"noise"];
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        // This filter will be responsible for flipping the input image upside down. It can't be 
        // fully prepared in advance because we need to know the height of the image.
        CIFilter *transform = [CIFilter filterWithName:@"CIAffineTransform"];
        
        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:WLCalendarBackgroundActiveBlur] forKey:@"inputRadius"];

        _blurInputFilter = [transform retain];
        _blurOutputFilter = [filter retain];
    }

    return self;
}

- (CGImageRef)newCGImageOfScreenBelowWindow:(NSWindow *)aWindow
{
    BEGIN_TIMING();

    CGRect windowRect = NSRectToCGRect([aWindow frame]);
    windowRect.origin.y = NSMaxY([[aWindow screen] frame]) - NSMaxY([aWindow frame]);
    
    CGWindowID windowId = [aWindow windowNumber];
    CGImageRef desktopImage = CGWindowListCreateImage(windowRect, kCGWindowListOptionOnScreenBelowWindow, windowId, kCGWindowImageBoundsIgnoreFraming);

    END_TIMING(@"capture background");

    return desktopImage;
}

- (CIImage *)blurredBackgroundImage
{  
    BEGIN_TIMING();
    CGImageRef backgroundImage = [self newCGImageOfScreenBelowWindow:[self window]];
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

#pragma mark NSView

- (void)viewWillDraw
{
    dispatch_once(&_didWarmUp, ^{
        [self blurredBackgroundImage];
        [NSImage imageNamed:@"calendar-background-active-top-left"];
        [NSImage imageNamed:@"calendar-background-active-top-middle"];
        [NSImage imageNamed:@"calendar-background-active-top-right"];
        [NSImage imageNamed:@"calendar-background-active-middle-left"];
        [NSImage imageNamed:@"calendar-background-active-middle-middle"];
        [NSImage imageNamed:@"calendar-background-active-middle-right"];
        [NSImage imageNamed:@"calendar-background-active-bottom-left"];
        [NSImage imageNamed:@"calendar-background-active-bottom-middle"];
        [NSImage imageNamed:@"calendar-background-active-bottom-right"];
        [NSImage imageNamed:@"noise"];
        [NSImage imageNamed:@"calendar-background-top-left"];
        [NSImage imageNamed:@"calendar-background-top-middle"];
        [NSImage imageNamed:@"calendar-background-top-right"];
        [NSImage imageNamed:@"calendar-background-middle-left"];
        [NSImage imageNamed:@"calendar-background-middle-middle"];
        [NSImage imageNamed:@"calendar-background-middle-right"];
        [NSImage imageNamed:@"calendar-background-bottom-left"];
        [NSImage imageNamed:@"calendar-background-bottom-middle"];
        [NSImage imageNamed:@"calendar-background-bottom-right"];
    });
    [super viewWillDraw];
}

- (void)drawRect:(NSRect)aDirtyRect
{
    BEGIN_TIMING();
    
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
#ifndef DEBUG_LAYERS
    NSRect innerArea = [[self class] glassRectForBounds:[self bounds]];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5];

    if ([[self window] level] >= NSFloatingWindowLevel)
    {
        [NSGraphicsContext saveGraphicsState];
        [innerPath addClip];
        CIImage *blurredBackgroundImage = [self blurredBackgroundImage];
        CGRect blurredRect = [blurredBackgroundImage extent];
        
        [blurredBackgroundImage drawAtPoint:NSMakePoint(blurredRect.origin.x, blurredRect.origin.y)
                                   fromRect:NSRectFromCGRect(blurredRect)
                                  operation:NSCompositeSourceOver
                                   fraction:1.0];
        
        // Slightly darken the background with a blueish tint.
        [[NSColor colorWithCalibratedRed:21.0 / 255.0 green:44.0 / 255.0 blue:73.0 / 255.0 alpha:WLCalendarBackgroundActiveDarkness] set];
        [innerPath fill];
               
        [NSGraphicsContext restoreGraphicsState];
        
        WLDrawScaledNinePartImage([self bounds],
                                  [NSImage imageNamed:@"calendar-background-active-top-left"],
                                  [NSImage imageNamed:@"calendar-background-active-top-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-top-right"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-left"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-middle-right"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-left"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-middle"],
                                  [NSImage imageNamed:@"calendar-background-active-bottom-right"],
                                  NSCompositeSourceOver,
                                  1.0f,
                                  YES);
    }
    else 
    {
        WLDrawScaledNinePartImage([self bounds],
                                  [NSImage imageNamed:@"calendar-background-top-left"],
                                  [NSImage imageNamed:@"calendar-background-top-middle"],
                                  [NSImage imageNamed:@"calendar-background-top-right"],
                                  [NSImage imageNamed:@"calendar-background-middle-left"],
                                  [NSImage imageNamed:@"calendar-background-middle-middle"],
                                  [NSImage imageNamed:@"calendar-background-middle-right"],
                                  [NSImage imageNamed:@"calendar-background-bottom-left"],
                                  [NSImage imageNamed:@"calendar-background-bottom-middle"],
                                  [NSImage imageNamed:@"calendar-background-bottom-right"],
                                  NSCompositeSourceOver,
                                  1.0f,
                                  YES);
    }

    NSImage *noiseImage = [NSImage imageNamed:@"noise"];
    [innerPath addClip];
    
    NSDrawNinePartImage(innerArea, nil, nil, nil, nil, noiseImage, nil, nil, nil, nil, NSCompositeSourceOver, 0.03, NO);

#else
    [[NSColor lightGrayColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    [NSGraphicsContext restoreGraphicsState];

    END_TIMING(@"draw background");
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)addSubview:(NSView *)aView
{
    NSAssert([[self subviews] count] == 0, @"WLCalendarWindowBackgroundView can have only one subview");
    [super addSubview:aView];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    NSWindow *w = [self window];
    NSView *realContentView = [[self subviews] lastObject];
    [realContentView setFrame:[w contentRectForFrameRect:[w frame]]];
}

@end
