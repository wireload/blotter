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


const CGFloat _WLYPadding = 6.0f;
const CGFloat _WLXPadding = 10.0f;


@implementation WLCalendarEventLayer

#pragma mark Properties
@dynamic title;
@dynamic location;
@dynamic keepTextVisible;


#pragma mark Methods

+ (CGFloat)minimumHumanVisibleWidth
{
    return _WLXPadding + 30.0f;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    return [self _preferredTitleHeightWithWidth:aWidth] + [self _preferredLocationHeightWithWidth:aWidth] + _WLYPadding;
}

- (CGFloat)minimumHumanVisibleHeight
{
    if (!_shouldUpdateMinimumHeightCache)
        return _cachedMinimumHeight;
    else
    {
        NSAttributedString *visibleString = [self.title length] > 0 ? self.title : self.location;
        _cachedMinimumHeight = 0.0f;
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)visibleString);
        if (framesetter != NULL)
        {
            CGMutablePathRef framePath = CGPathCreateMutable();
            CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, self.bounds.size.width - _WLXPadding, 9999.0f));
            CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
            if (frame != NULL)
            {
                NSArray *lines = (NSArray *)CTFrameGetLines(frame);
                if ([lines count] == 1)
                    _cachedMinimumHeight = AB_CTFrameGetSize(frame).height;
                else
                {
                    CGPoint origins[2];
                    CTFrameGetLineOrigins(frame, CFRangeMake(0, 2), origins);
                    _cachedMinimumHeight = origins[0].y - origins[1].y;
                }
                CFRelease(frame);
            }
            CFRelease(framePath);
            CFRelease(framesetter);
        }
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

    CGColorRef lineColor = CGColorCreateCopyWithAlpha([[NSColor whiteColor] WL_CGColor], self.contentsBackgroundOpacity);
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGColorRelease(lineColor);
    if (self.cornerRadius == 0.0f)
    {
        CGContextBeginPath(aContext);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, self.bounds.origin.y);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), self.bounds.origin.y);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, CGRectGetMaxY(self.bounds));
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds));
        CGContextStrokePath(aContext);
    }
    else
    {
        CGContextBeginPath(aContext);
        CGContextMoveToPoint(aContext, self.bounds.origin.x, self.cornerRadius);
        CGContextAddArcToPoint(aContext,
                               self.bounds.origin.x,
                               self.bounds.origin.y,
                               self.bounds.origin.x + self.cornerRadius,
                               self.bounds.origin.y,
                               self.cornerRadius);
        CGContextAddArcToPoint(aContext,
                               self.bounds.origin.x + self.bounds.size.width,
                               self.bounds.origin.y,
                               self.bounds.origin.x + self.bounds.size.width,
                               self.bounds.origin.x + self.cornerRadius,
                               self.cornerRadius);
        CGContextAddArcToPoint(aContext,
                               self.bounds.origin.x + self.bounds.size.width,
                               self.bounds.origin.y + self.bounds.size.height,
                               self.bounds.origin.x + self.bounds.size.width - self.cornerRadius,
                               self.bounds.origin.y + self.bounds.size.height,
                               self.cornerRadius);
        CGContextAddArcToPoint(aContext,
                               self.bounds.origin.x,
                               self.bounds.origin.y + self.bounds.size.height,
                               self.bounds.origin.x,
                               self.bounds.origin.y,
                               self.cornerRadius);
        CGContextAddLineToPoint(aContext, self.bounds.origin.x, self.bounds.origin.y);
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
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, 1.0f), 0.0f, [[NSColor WL_eventShadowColor] WL_CGColor]);

        CGFloat preferredTitleHeight = [self _preferredTitleHeightWithWidth:self.bounds.size.width];
        if (preferredTitleHeight < titleAndLocationFrame.size.height)
        {
            CGFloat titleHeight = preferredTitleHeight;
            CGFloat preferredLocationHeight = [self _preferredLocationHeightWithWidth:self.bounds.size.width];
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
            [self _drawString:self.title inContext:aContext rect:titleFrame];
            CGRect locationFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                             CGRectGetMinY(titleFrame) - locationHeight,
                                                             titleAndLocationFrame.size.width,
                                                             locationHeight));
            [self _drawString:self.location inContext:aContext rect:locationFrame];
        }
        else
        {
            // Layer cannot fit title, so there is no need to draw location.
            [self _drawString:self.title inContext:aContext rect:titleAndLocationFrame];
        }
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Avoid drawing string");
#endif
    CGContextRestoreGState(aContext);
}

- (CGSize)_preferredTitleSize
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.title);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, 9999.0f, 9999.0f));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            preferredFrameSize = AB_CTFrameGetSize(frame);
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    return CGSizeMake(ceilf(preferredFrameSize.width), ceilf(preferredFrameSize.height));
}

- (CGSize)_preferredLocationSize
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.location);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, 9999.0f, 9999.0f));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            preferredFrameSize = AB_CTFrameGetSize(frame);
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    return CGSizeMake(ceilf(preferredFrameSize.width), ceilf(preferredFrameSize.height));
}

- (CGFloat)_preferredTitleHeightWithWidth:(CGFloat)aWidth
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.title);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, aWidth - _WLXPadding, 9999.0f));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            preferredFrameSize = AB_CTFrameGetSize(frame);
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    return ceilf(preferredFrameSize.height);
}

- (CGFloat)_preferredLocationHeightWithWidth:(CGFloat)aWidth
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.location);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, aWidth - _WLXPadding, 9999.0f));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            preferredFrameSize = AB_CTFrameGetSize(frame);
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    return ceilf(preferredFrameSize.height);
}

- (void)_drawString:(NSAttributedString *)aString inContext:(CGContextRef)aContext rect:(CGRect)aRect
{
    CGContextSaveGState(aContext);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)aString);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, aRect);
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            __block NSArray *lines = (NSArray *)CTFrameGetLines(frame);
            NSUInteger numberOfLines = [lines count];
            if (numberOfLines > 0)
            {
                __block CGPoint *lineOrigins = calloc(numberOfLines, sizeof(CGPoint));
                CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);

                CFRange frameRange = CTFrameGetVisibleStringRange(frame);
                CFIndex stringLength = [aString length];
                NSParameterAssert((NSUInteger)stringLength == [aString length]);
                BOOL shouldTruncateLastLine = (frameRange.location + frameRange.length) < stringLength;

                [lines enumerateObjectsUsingBlock:^(id line, NSUInteger idx, BOOL *stop)
                 {
                     CGPoint origin = lineOrigins[idx];
                     CGContextSetTextPosition(aContext, aRect.origin.x + origin.x, aRect.origin.y + origin.y);

                     if (idx != numberOfLines - 1 || !shouldTruncateLastLine)
                         CTLineDraw((CTLineRef)line, aContext);
                     else
                     {
                         CFRange lineRange = CTLineGetStringRange((CTLineRef)line);
                         NSRange range = NSMakeRange(lineRange.location, lineRange.length);
                         NSMutableAttributedString *truncatedString = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                                       [aString attributedSubstringFromRange:range]];
                         NSString *trimmedString = [[truncatedString string] stringByTrimmingCharactersInSet:
                                                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                         [[truncatedString mutableString] setString:trimmedString];
                         static const CFStringRef Token = CFSTR("\u2026");
                         [[truncatedString mutableString] appendString:(NSString *)Token];
                         CTLineRef truncatedLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncatedString);
                         [truncatedString release];
                         if (truncatedLine != NULL)
                         {
                             CTLineRef truncationToken = NULL;
                             CFDictionaryRef tokenAttributes = (CFDictionaryRef)[aString attributesAtIndex:0 effectiveRange:NULL];
                             CFAttributedStringRef truncationString = CFAttributedStringCreate(NULL,
                                                                                               Token,
                                                                                               tokenAttributes);
                             truncationToken = CTLineCreateWithAttributedString(truncationString);
                             CFRelease(truncationString);
                             // In case when adding truncation symbol to the end of line make the line to not fit the bounds.
                             CTLineRef truncatedTruncatedLine = CTLineCreateTruncatedLine(truncatedLine,
                                                                                          aRect.size.width,
                                                                                          kCTLineTruncationEnd,
                                                                                          truncationToken);
                             CFRelease(truncationToken);
                             if (truncatedTruncatedLine != NULL)
                             {
                                 CTLineDraw(truncatedTruncatedLine, aContext);
                                 CFRelease(truncatedTruncatedLine);
                             }
                             else
                                 CTLineDraw(truncatedLine, aContext);
                             CFRelease(truncatedLine);
                         }
                         else
                             CTLineDraw((CTLineRef)line, aContext);
                     }
                 }];
                free(lineOrigins);
            }
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    CGContextRestoreGState(aContext);
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

    CGSize preferredTitleSize = [self _preferredTitleSize];
    CGSize preferredLocationSize = [self _preferredLocationSize];
    return CGSizeMake(ceilf(fmaxf(preferredTitleSize.width, preferredLocationSize.width) + _WLXPadding),
                      ceilf(preferredTitleSize.height + preferredLocationSize.height + _WLYPadding));
}

- (BOOL)contentsAreFlipped
{
    return YES;
}


#pragma mark NSObject

- (void)didChangeValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"] || [aKey isEqualToString:@"location"])
        _shouldUpdateMinimumHeightCache = YES;
    [super didChangeValueForKey:aKey];
}

@end
