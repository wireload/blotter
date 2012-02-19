//
//  NSAttributedString.m
//  Blotter
//
//  Created by Ilya Kulakov on 21.09.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#include <tgmath.h>
#import "NSAttributedString+WLStringDrawing.h"
#import "CoreText+Additions.h"


@implementation NSAttributedString (WLStringDrawing)

- (void)WL_drawWithRect:(CGRect)aRect context:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
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
                CFIndex stringLength = [self length];
                NSParameterAssert((NSUInteger)stringLength == [self length]);
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
                                                                      [self attributedSubstringFromRange:range]];
                        NSString *trimmedString = [[truncatedString string] stringByTrimmingCharactersInSet:
                                                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        static const CFStringRef Token = CFSTR("\u2026");
                        [[truncatedString mutableString] setString:[trimmedString stringByAppendingString:(NSString *)Token]];
                        CTLineRef truncatedLine = CTLineCreateWithAttributedString((CFAttributedStringRef)truncatedString);
                        [truncatedString release];
                        if (truncatedLine != NULL)
                        {
                            CTLineRef truncationToken = NULL;
                            CFDictionaryRef tokenAttributes = (CFDictionaryRef)[self attributesAtIndex:0 effectiveRange:NULL];
                            CFAttributedStringRef truncationString = CFAttributedStringCreate(NULL,
                                                                                              Token,
                                                                                              tokenAttributes);
                            truncationToken = CTLineCreateWithAttributedString(truncationString);
                            CFRelease(truncationString);
                            // In case when adding truncation symbol make the line to exceed aRect.
                            CTLineRef truncatedTruncatedLine = CTLineCreateTruncatedLine(truncatedLine,
                                                                                         aRect.size.width - origin.x,
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

- (CGSize)WL_preferredSize
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
    if (framesetter != NULL)
    {
        static CGPathRef FramePath = NULL;
        static dispatch_once_t FramePathOnceToken;
        dispatch_once(&FramePathOnceToken, ^{
            FramePath = CGPathCreateWithRect(CGRectMake(0.0,
                                                        0.0,
                                                        9999.0,
                                                        9999.0),
                                             NULL);
        });
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), FramePath, NULL);
        if (frame != NULL)
        {
            preferredFrameSize = AB_CTFrameGetSize(frame);
            CFRelease(frame);
        }
        CFRelease(framesetter);
    }
    return CGSizeMake(ceil(preferredFrameSize.width),
                      ceil(preferredFrameSize.height));
}

- (CGFloat)WL_preferredHeightWithWidth:(CGFloat)aWidth
{
    CGSize preferredFrameSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, aWidth, 9999.0f));
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

- (CGFloat)WL_firstLineHeightWithWidth:(CGFloat)aWidth
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self);
    CGFloat height = 0.0f;
    if (framesetter != NULL)
    {
        CGMutablePathRef framePath = CGPathCreateMutable();
        CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, aWidth, 9999.0f));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
        if (frame != NULL)
        {
            NSArray *lines = (NSArray *)CTFrameGetLines(frame);
            if ([lines count] == 1)
                height = AB_CTFrameGetSize(frame).height;
            else
            {
                CGPoint origins[2];
                CTFrameGetLineOrigins(frame, CFRangeMake(0, 2), origins);
                height = origins[0].y - origins[1].y;
            }
            CFRelease(frame);
        }
        CFRelease(framePath);
        CFRelease(framesetter);
    }
    return ceilf(height);
}

@end
