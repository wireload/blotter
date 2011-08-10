//
//  WLCalendarEventLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarEventLayer.h"
#import "CATextLayer+WLStringSize.h"
#import "NSColor+CGColor.h"
#import "CoreText+Additions.h"


const CGFloat _WLYPadding = 10.0f;
const CGFloat _WLXPadding = 10.0f;


@implementation WLCalendarEventLayer
@dynamic string;

+ (CGFloat)minimalHumanVisibleWidth
{
    return _WLXPadding + 30.0f;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGSize preferredFrameSize = CGSizeMake(0.0f, 0.0f);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.string);
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
    return preferredFrameSize.height + _WLYPadding;
}

- (CGFloat)minimalHumanVisibleHeight
{
    if (!_shouldUpdateMinimalHeightCache)
        return _cachedMinimalHeight;
    else
    {
        _cachedMinimalHeight = 0.0f;
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.string);
        if (framesetter != NULL)
        {
            CGMutablePathRef framePath = CGPathCreateMutable();
            CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, self.bounds.size.width - _WLXPadding, 9999.0f));
            CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
            if (frame != NULL)
            {
                NSArray *lines = (NSArray *)CTFrameGetLines(frame);
                if ([lines count] == 1)
                    _cachedMinimalHeight = AB_CTFrameGetSize(frame).height;
                else
                {
                    CGPoint origins[2];
                    CTFrameGetLineOrigins(frame, CFRangeMake(0, 2), origins);
                    _cachedMinimalHeight = origins[0].y - origins[1].y;
                }
                CFRelease(frame);
            }
            CFRelease(framePath);
            CFRelease(framesetter);
        }
        _cachedMinimalHeight += _WLYPadding;
        _shouldUpdateMinimalHeightCache = NO;
        return _cachedMinimalHeight;
    }
}


#pragma mark Private

- (void)_drawBackground:(CGContextRef)aContext
{
    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    CGContextSetFillColorWithColor(aContext, backgroundColor);
    CGContextFillRect(aContext, self.bounds);
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
                                self.bounds.origin,
                                CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds)),
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
}

- (void)_drawString:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGRect stringBounds = CGRectInset(self.bounds, _WLXPadding / 2, _WLYPadding / 2);
    CGRect markedArea = CGContextGetClipBoundingBox(aContext);
    if (CGRectIntersectsRect(stringBounds, markedArea))
    {
#ifdef DEBUG_LAYERS
        CGContextSetFillColorWithColor(aContext, [[NSColor greenColor] WL_CGColor]);
        CGContextFillRect(aContext, stringBounds);
#endif
        CGContextSetTextMatrix(aContext, CGAffineTransformIdentity);
        CGContextTranslateCTM(aContext, 0.0f, self.bounds.size.height);
        CGContextScaleCTM(aContext, 1.0f, -1.0f);
        CGContextSetShouldSmoothFonts(aContext, YES);
        CGContextSetAllowsFontSmoothing(aContext, YES);
        CGContextSetShouldAntialias(aContext, YES);
        CGContextSetAllowsAntialiasing(aContext, YES);
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.string);
        if (framesetter != NULL)
        {
            CGMutablePathRef framePath = CGPathCreateMutable();
            CGPathAddRect(framePath, NULL, stringBounds);
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
                    CFIndex stringLength = [self.string length];
                    NSParameterAssert((NSUInteger)stringLength == [self.string length]);
                    BOOL shouldTruncateLastLine = (frameRange.location + frameRange.length) < stringLength;

                    [lines enumerateObjectsUsingBlock:^(id line, NSUInteger idx, BOOL *stop)
                    {
                         CGPoint origin = lineOrigins[idx];
                         CGContextSetTextPosition(aContext, stringBounds.origin.x + origin.x, stringBounds.origin.y + origin.y);

                         if (idx != numberOfLines - 1 || !shouldTruncateLastLine)
                             CTLineDraw((CTLineRef)line, aContext);
                         else
                         {
                             CFRange lineRange = CTLineGetStringRange((CTLineRef)line);
                             NSRange range = NSMakeRange(lineRange.location, lineRange.length);
                             NSMutableAttributedString *truncatedString = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                                           [self.string attributedSubstringFromRange:range]];
                             NSString *trimmedString = [[truncatedString string] stringByTrimmingCharactersInSet:
                                                        [NSCharacterSet newlineCharacterSet]];
                             [[truncatedString mutableString] setString:trimmedString];
                             [[truncatedString mutableString] appendString:(NSString *)CFSTR("\u2026")];
                             CTLineRef truncatedLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncatedString);
                             [truncatedString release];
                             if (truncatedLine != NULL)
                             {
                                 CTLineRef truncationToken = NULL;
                                 CFStringRef token = CFSTR("\u2026");
                                 CFDictionaryRef tokenAttributes = (CFDictionaryRef)[self.string attributesAtIndex:0 effectiveRange:NULL];
                                 CFAttributedStringRef truncationString = CFAttributedStringCreate(NULL,
                                                                                                   token,
                                                                                                   tokenAttributes);
                                 truncationToken = CTLineCreateWithAttributedString(truncationString);
                                 CFRelease(truncationString);
                                 // In case when adding truncation symbol to the end of line make the line to not fit the bounds.
                                 CTLineRef truncatedTruncatedLine = CTLineCreateTruncatedLine(truncatedLine,
                                                                                              stringBounds.size.width,
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
    }
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Avoid drawing string");
#endif
    CGContextRestoreGState(aContext);
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"string"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
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

    CGSize preferredFrameSize = CGSizeMake(0.0f, 0.0f);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.string);
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
    return CGSizeMake(preferredFrameSize.width + _WLXPadding, preferredFrameSize.height + _WLYPadding);
}


#pragma mark NSObject

- (void)didChangeValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"string"])
    {
        _shouldUpdateMinimalHeightCache = YES;
    }
}

@end
