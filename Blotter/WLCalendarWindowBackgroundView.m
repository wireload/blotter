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

- (CGImageRef)createCGImageOfScreenBelowWindow:(NSWindow *)aWindow
{
    // To properly map screen coordinates (meaning that 0,0 point is lower left corner of the screen with main menu)
    // we need to calculate _minimal_ offset to the left border (always <= 0, cause left-side windows (relative to the screen with main menu) always have negative x)
    // and _maximal_ offset to the top border (always > 0, cause it cannot be less than height of the screen with main menu)
    CGFloat mapX = 0, mapY = 0;
    for (NSScreen *screen in [NSScreen screens]) {
        mapX = MIN([screen frame].origin.x, mapX);
        mapY = MAX(NSMaxY([screen frame]), mapY);
    }
    assert(mapX <= 0);
    assert(mapY > 0);
    
    CGWindowID windowId = [aWindow windowNumber];
    CGImageRef desktopImage = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenBelowWindow, windowId, kCGWindowImageDefault);
    
    // Get window frame in screen coordinates
    CGRect screenWindowFrame = NSRectToCGRect([aWindow frame]);
    //DLOG(@"Window frame in screen coordinates: %@", NSStringFromRect(screenWindowFrame));
    
    // Get window frame in desktop image coordinates
    CGRect imageWindowFrame = CGRectMake(screenWindowFrame.origin.x - mapX,
                                         -screenWindowFrame.origin.y + mapY - screenWindowFrame.size.height,
                                         screenWindowFrame.size.width,
                                         screenWindowFrame.size.height);
    // DLOG(@"Window frame in desktop image coordinates: %@", NSStringFromRect(imageWindowFrame));
    CGImageRef screenBelowWindowImage = CGImageCreateWithImageInRect(desktopImage, imageWindowFrame);
    CFRelease(desktopImage);
    
    return screenBelowWindowImage;
}

- (CIImage *)blurredBackgroundImage
{  
    CGImageRef backgroundImage = [self createCGImageOfScreenBelowWindow:[self window]];
    CIImage *ciImage = [CIImage imageWithCGImage:backgroundImage];

    // Flip image upside down.
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:0 yBy:[ciImage extent].size.height];
    [affineTransform scaleXBy:1.0 yBy:-1.0];
    
    CIFilter *transform = [CIFilter filterWithName:@"CIAffineTransform"];
    [transform setValue:ciImage forKey:@"inputImage"];
    [transform setValue:affineTransform forKey:@"inputTransform"];

    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setDefaults];
    [filter setValue:[transform valueForKey:@"outputImage"] forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:WLCalendarBackgroundActiveBlur] forKey:@"inputRadius"];

    CIImage *result = [filter valueForKey:@"outputImage"];

    CFRelease(backgroundImage);
    
    return result;
}

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [NSGraphicsContext saveGraphicsState];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
#ifndef DEBUG_LAYERS
    NSRect innerArea = [[self class] glassRectForBounds:[self bounds]];
    NSBezierPath *innerPath = [NSBezierPath bezierPathWithRoundedRect:innerArea xRadius:5 yRadius:5];

    if ([[self window] level] >= NSFloatingWindowLevel)
    {
        [NSGraphicsContext saveGraphicsState];
        [innerPath setClip];
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
    [innerPath setClip];
    
    NSDrawNinePartImage(innerArea, nil, nil, nil, nil, noiseImage, nil, nil, nil, nil, NSCompositeSourceOver, 0.03, NO);

#else
    [[NSColor lightGrayColor] setFill];
    NSRectFill(aDirtyRect);
#endif
    [NSGraphicsContext restoreGraphicsState];
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
