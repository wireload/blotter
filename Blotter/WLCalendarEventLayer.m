//
//  WLCalendarEventLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarEventLayer.h"
#import "NSColor+WLCalendar.h"


const CGFloat _WLYPadding = 6.0f;
const CGFloat _WLXPadding = 10.0f;


@implementation WLCalendarEventLayer

#pragma mark Properties
@dynamic title;
@dynamic location;
@dynamic keepTextVisible;
@dynamic contentsBackgroundOpacity;
@dynamic contentsBackgroundColor;

- (void)setCornerRadius:(CGFloat)newCornerRadius
{
    if (newCornerRadius == 0.0f)
        self.borderWidth = 0.0f;
    else
    {
        self.borderColor = [self _lineColor];
        self.borderWidth = 1.0f;
    }
    [super setCornerRadius:newCornerRadius];
}


#pragma mark Methods

+ (CGFloat)minimumHumanVisibleWidth
{
    // At least 2 side-by-side events should be visible on 1280x800.
    // Width of column depends on user's locale. The widest locale is South Korea.
    // return _WLXPadding + 20.0f;

    // ...actually overlapping events look like a bug because their colours and text
    // mix. It's better to keep trying to render them side by side, no matter how
    // small.
    return 1.0;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    return [self.title WL_preferredHeightWithWidth:aWidth - _WLXPadding] + [self.location WL_preferredHeightWithWidth:aWidth - _WLXPadding] + _WLYPadding;
}

- (CGFloat)minimumHumanVisibleHeight
{
    NSAttributedString *visibleString = [self.title length] > 0 ? self.title : self.location;
    CGFloat minHeight = [visibleString WL_firstLineHeightWithWidth:self.bounds.size.width - _WLXPadding];
    minHeight += _WLYPadding;
    return minHeight;
}


#pragma mark Private

- (void)_drawBackground:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    NSColor *nsBackgroundColor = [[NSColor WL_NSColorFromCGColor:backgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    nsBackgroundColor = [NSColor colorWithCalibratedHue:[nsBackgroundColor hueComponent] saturation:fminf(1.0, [nsBackgroundColor saturationComponent] * 1.05) brightness:fminf(1.0, [nsBackgroundColor brightnessComponent] * 1.05) alpha:self.contentsBackgroundOpacity];
    CGContextSetFillColorWithColor(aContext, [nsBackgroundColor WL_CGColor]);
    if (self.cornerRadius == 0.0f)
        CGContextFillRect(aContext, CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height) );
    else
        CGContextFillRect(aContext, CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height) );
    CGColorRelease(backgroundColor);

    CGContextSaveGState(aContext);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(self.contentsBackgroundColor);
    CGFloat locations[2] = {0.0f, 1.0f};
    CGFloat components[8] = {
        0.0f, 0.0f, 0.0f, 0.0f,
        0.0f, 0.0f, 0.0f, 0.15f
    };
    CGGradientRef whiteToTransparent = CGGradientCreateWithColorComponents(colorSpace,
                                                                           components,
                                                                           locations,
                                                                           sizeof(locations) / sizeof(CGFloat));
    CGContextSetBlendMode(aContext, kCGBlendModeMultiply);
    CGContextDrawLinearGradient(aContext,
                                whiteToTransparent,
                                CGPointMake(self.bounds.origin.x, self.bounds.origin.y),
                                CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds)),
                                kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(whiteToTransparent);
    CGContextRestoreGState(aContext);


    if (self.cornerRadius == 0.0f)
    {
        self.borderWidth = 0.0f;
        CGContextSetLineWidth(aContext, 1.0f);
        CGContextSetShouldAntialias(aContext, NO);
        CGContextSetStrokeColorWithColor(aContext, [self _lineColor]);
        CGContextBeginPath(aContext);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, self.bounds.origin.y + 1.0f);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), self.bounds.origin.y + 1.0f);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, CGRectGetMaxY(self.bounds));
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
        CGContextStrokePath(aContext);
    }
    CGContextRestoreGState(aContext);
}

- (void)_drawString:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGRect titleAndLocationFrame = CGRectInset(self.bounds, _WLXPadding / 2, _WLYPadding / 2);
    CGRect dirtyRect = CGContextGetClipBoundingBox(aContext);
    if (CGRectIntersectsRect(titleAndLocationFrame, dirtyRect))
    {
        CGContextSetTextMatrix(aContext, CGAffineTransformIdentity);
        CGContextTranslateCTM(aContext, 0.0f, self.bounds.size.height);
        CGContextScaleCTM(aContext, 1.0f, -1.0f);
        CGContextSetShouldSmoothFonts(aContext, YES);
        CGContextSetAllowsFontSmoothing(aContext, YES);
        CGContextSetShouldAntialias(aContext, YES);
        CGContextSetAllowsAntialiasing(aContext, YES);
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, -1.0f), 0.0f, [[NSColor WL_eventTextShadowColor] WL_CGColor]);
        else
            CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, 1.0f), 0.0f, [[NSColor WL_eventTextShadowColor] WL_CGColor]);

        CGFloat preferredTitleHeight = [self.title WL_preferredHeightWithWidth:self.bounds.size.width - _WLXPadding];
        if (preferredTitleHeight < titleAndLocationFrame.size.height)
        {
            CGFloat titleHeight = preferredTitleHeight;
            CGFloat preferredLocationHeight = [self.location WL_preferredHeightWithWidth:self.bounds.size.width - _WLXPadding];
            CGFloat locationHeight = CGFLOAT_MAX;
            if (preferredTitleHeight + preferredLocationHeight < titleAndLocationFrame.size.height)
            {
                locationHeight = preferredLocationHeight;
                if (self.keepTextVisible)
                {
                    // Make text visible as much as possible.
                    // Visible rect's origin is top left, while context's origin is bottom left. Convert to context's coordinates.
                    CGFloat visibleRectTop = self.bounds.size.height - self.visibleRect.origin.y;
                    CGFloat visibleRectBottom = self.bounds.size.height - CGRectGetMaxY(self.visibleRect);
                    CGFloat maxY = CGRectGetMaxY(titleAndLocationFrame) - titleHeight - locationHeight;
                    CGFloat minY = titleAndLocationFrame.origin.y;
                    // If the parent layer fits the whole event layer, draw text as usual, otherwise center it.
                    CGFloat y = 0.0f;
                    BOOL isWholeEventLayerVisible = (visibleRectTop >= maxY && visibleRectBottom <= minY);
                    BOOL isEventLayerBecomeVisible = (visibleRectTop >= maxY && visibleRectBottom > minY);
                    if (isWholeEventLayerVisible || isEventLayerBecomeVisible)
                    {
                        y = visibleRectTop - titleHeight - locationHeight;
                        y = fminf(maxY, fmaxf(minY, y));
                    }
                    else
                    {
                        y = visibleRectBottom + ((visibleRectTop - visibleRectBottom) - (titleHeight + locationHeight)) / 2.0f;
                        y = fminf(maxY, fmaxf(minY, y));
                    }
                    titleAndLocationFrame.origin.y = y;
                    titleAndLocationFrame.size.height = titleHeight + locationHeight;
                }
            }
            else
                locationHeight = titleAndLocationFrame.size.height - titleHeight;

            CGRect titleFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                          CGRectGetMaxY(titleAndLocationFrame) - titleHeight,
                                                          titleAndLocationFrame.size.width,
                                                          titleHeight));
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[NSColor greenColor] WL_CGColor]);
            CGContextFillRect(aContext, titleFrame);
#endif
            [self.title WL_drawWithRect:titleFrame context:aContext];
            CGRect locationFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                             CGRectGetMinY(titleFrame) - locationHeight,
                                                             titleAndLocationFrame.size.width,
                                                             locationHeight));
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[[NSColor greenColor] colorWithAlphaComponent:0.8f] WL_CGColor]);
            CGContextFillRect(aContext, locationFrame);
#endif
            [self.location WL_drawWithRect:locationFrame context:aContext];
        }
        else
        {
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[[NSColor greenColor] colorWithAlphaComponent:0.3f] WL_CGColor]);
            CGContextFillRect(aContext, titleAndLocationFrame);
#endif
            // Layer cannot fit title, so there is no need to draw location.
            [self.title WL_drawWithRect:titleAndLocationFrame context:aContext];
        }
    }
    CGContextRestoreGState(aContext);
}

- (CGColorRef)_lineColor
{
    CGColorRef lineColor = CGColorCreateCopyWithAlpha([[NSColor whiteColor] WL_CGColor], 0.25);
    return (CGColorRef)[(id)lineColor autorelease];
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"])
        return YES;
    else if ([aKey isEqualToString:@"location"])
        return YES;
    else if ([aKey isEqualToString:@"keepTextVisible"])
        return YES;
    else if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return YES;
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey {
    if ([aKey isEqualToString:@"keepTextVisible"])
        return [NSNumber numberWithBool:NO];
    else if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [NSNumber numberWithFloat:1.0f];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return (id)[[NSColor clearColor] WL_CGColor];
    else
        return [super defaultValueForKey:aKey];
}

+ (id<CAAction>)defaultActionForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundOpacity"];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundColor"];
    else
        return [super defaultActionForKey:aKey];
}

- (id<CAAction>)actionForKey:(NSString *)aKey
{
    id<CAAction> action = [super actionForKey:aKey];
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundOpacity"]];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundColor"]];
    return action;
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
#ifndef DEBUG_LAYERS
    [self _drawBackground:aContext];
#endif
    // It's important to draw background before text to make antialiasing possible.
    [self _drawString:aContext];
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGSize preferredTitleSize = [self.title WL_preferredSize];
    CGSize preferredLocationSize = [self.location WL_preferredSize];
    return CGSizeMake(ceilf(fmaxf(preferredTitleSize.width, preferredLocationSize.width) + _WLXPadding),
                      ceilf(preferredTitleSize.height + preferredLocationSize.height + _WLYPadding));
}

@end
