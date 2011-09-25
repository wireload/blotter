//
//  WLCalendarEventLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarEventLayer.h"
#import "NSColor+CGColor.h"
#import "CoreText+Additions.h"
#import "NSColor+WLCalendar.h"
#import "NSAttributedString+WLStringDrawing.h"


const CGFloat _WLYPadding = 6.0f;
const CGFloat _WLXPadding = 10.0f;


@implementation WLCalendarEventLayer

#pragma mark Properties
@dynamic title;
@dynamic location;
@dynamic keepTextVisible;

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
    return _WLXPadding + 20.0f;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    return [self.title WL_preferredHeightWithWidth:aWidth - _WLXPadding] + [self.location WL_preferredHeightWithWidth:aWidth - _WLXPadding] + _WLYPadding;
}

- (CGFloat)minimumHumanVisibleHeight
{
    if (!_shouldUpdateMinimumHeightCache)
        return _cachedMinimumHeight;
    else
    {
        NSAttributedString *visibleString = [self.title length] > 0 ? self.title : self.location;
        _cachedMinimumHeight = [visibleString WL_firstLineHeightWithWidth:self.bounds.size.width - _WLXPadding];
        _cachedMinimumHeight += _WLYPadding;
        _shouldUpdateMinimumHeightCache = NO;
        return _cachedMinimumHeight;
    }
}


#pragma mark Private

- (void)_drawBackground:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    CGContextSetFillColorWithColor(aContext, backgroundColor);
    if (self.cornerRadius == 0.0f)
        CGContextFillRect(aContext, CGRectMake(self.bounds.origin.x, self.bounds.origin.y + 1.0f, self.bounds.size.width, self.bounds.size.height - 2.0f) );
    else
        CGContextFillRect(aContext, CGRectMake(self.bounds.origin.x + 1.0f, self.bounds.origin.y + 1.0f, self.bounds.size.width - 2.0f, self.bounds.size.height - 2.0f) );
    CGColorRelease(backgroundColor);

    CGContextSaveGState(aContext);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(self.contentsBackgroundColor);
    CGFloat locations[2] = {0.0f, 1.0f};
    CGFloat components[8] = {1.0f, 1.0f, 1.0f, 0.6f * self.contentsBackgroundOpacity,
        0.0f, 0.0f, 0.0f, 0.0f};
    CGGradientRef whiteToTransparent = CGGradientCreateWithColorComponents(colorSpace,
                                                                           components,
                                                                           locations,
                                                                           sizeof(locations) / sizeof(CGFloat));
    CGContextSetBlendMode(aContext, kCGBlendModeOverlay);
    CGContextDrawLinearGradient(aContext,
                                whiteToTransparent,
                                CGPointMake(self.bounds.origin.x, self.bounds.origin.y + 1.0f),
                                CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - 1.0f),
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
        CGContextMoveToPoint(aContext, self.bounds.origin.x + 1.0f, self.bounds.origin.y + 1.0f);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), self.bounds.origin.y);
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
                    // Layer's origin is top left, while context's origin is bottom left.
                    CGFloat visibleRectTop = self.bounds.size.height - self.visibleRect.origin.y;
                    CGFloat y = fminf(CGRectGetMaxY(titleAndLocationFrame) - titleHeight - locationHeight,
                                      fmaxf(titleAndLocationFrame.origin.y,
                                            visibleRectTop - titleHeight - locationHeight));
                    titleAndLocationFrame.origin.y = y;
                    titleAndLocationFrame.size.height = titleHeight + locationHeight;
                }
            }
            else
                locationHeight = titleAndLocationFrame.size.height - titleHeight;

#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[NSColor greenColor] WL_CGColor]);
            CGContextFillRect(aContext, titleAndLocationFrame);
#endif
            CGRect titleFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                          CGRectGetMaxY(titleAndLocationFrame) - titleHeight,
                                                          titleAndLocationFrame.size.width,
                                                          titleHeight));
            [self.title WL_drawWithRect:titleFrame context:aContext];
            CGRect locationFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                             CGRectGetMinY(titleFrame) - locationHeight,
                                                             titleAndLocationFrame.size.width,
                                                             locationHeight));
            [self.location WL_drawWithRect:locationFrame context:aContext];
        }
        else
        {
            // Layer cannot fit title, so there is no need to draw location.
            [self.title WL_drawWithRect:titleAndLocationFrame context:aContext];
        }
    }
    CGContextRestoreGState(aContext);
}

- (CGColorRef)_lineColor
{
    CGColorRef lineColor = CGColorCreateCopyWithAlpha([[NSColor whiteColor] WL_CGColor], self.contentsBackgroundOpacity);
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
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey {
    if ([aKey isEqualToString:@"keepTextVisible"])
        return [NSNumber numberWithBool:NO];
    else
        return [super defaultValueForKey:aKey];
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


#pragma mark NSObject

- (void)didChangeValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"] || [aKey isEqualToString:@"location"])
        _shouldUpdateMinimumHeightCache = YES;
    [super didChangeValueForKey:aKey];
}

@end
