//
//  WLCalendarTextLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTextLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSColor+CGColor.h"
#import "CoreText+Additions.h"


@implementation WLCalendarTextLayer

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }

    return self;
}


#pragma mark Properties
@dynamic string;
@dynamic font;
@dynamic foregroundColor;
@dynamic stringShadowOffset;
@dynamic stringShadowColor;
@dynamic stringShadowRadius;
@dynamic alignmentMode;


#pragma mark Private

- (NSAttributedString *)_attributedString
{
    CTTextAlignment a;
    if ([self.alignmentMode isEqualToString:kCAAlignmentCenter])
        a = kCTCenterTextAlignment;
    else if ([self.alignmentMode isEqualToString:kCAAlignmentLeft])
        a = kCTLeftTextAlignment;
    else if ([self.alignmentMode isEqualToString:kCAAlignmentRight])
        a = kCTRightTextAlignment;
    else if ([self.alignmentMode isEqualToString:kCAAlignmentJustified])
        a = kCTJustifiedTextAlignment;
    else if ([self.alignmentMode isEqualToString:kCAAlignmentNatural])
        a = kCTNaturalTextAlignment;
    CTParagraphStyleSetting alignmentSetting = {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = &a};
    CTParagraphStyleRef p = CTParagraphStyleCreate(&alignmentSetting, 1);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                (id)self.font,              (id)kCTFontAttributeName,
                                (id)self.foregroundColor,   (id)kCTForegroundColorAttributeName,
                                (id)p,                      (id)kCTParagraphStyleAttributeName, nil];
    CFRelease(p);
    return [[[NSAttributedString alloc] initWithString:self.string attributes:attributes] autorelease];
}


#pragma mark CALayer;

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"foregroundColor"])
        return (id)[[NSColor whiteColor] WL_CGColor];
    else if ([aKey isEqualToString:@"stringShadowOffset"])
        return [NSValue valueWithSize:NSMakeSize(0.0f, 1.0f)];
    else if ([aKey isEqualToString:@"stringShadowRadius"])
        return [NSNumber numberWithFloat:0.0f];
    else if ([aKey isEqualToString:@"alignmentMode"])
        return kCAAlignmentNatural;
    else
        return [super defaultValueForKey:aKey];
}

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"string"])
        return YES;
    else if ([aKey isEqualToString:@"font"])
        return YES;
    else if ([aKey isEqualToString:@"stringShadowOffset"])
        return YES;
    else if ([aKey isEqualToString:@"stringShadowColor"])
        return YES;
    else if ([aKey isEqualToString:@"stringShadowRadius"])
        return YES;
    else if ([aKey isEqualToString:@"foregroundColor"])
        return YES;
    else if ([aKey isEqualToString:@"alignmentMode"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGRect dirtyRect = CGContextGetClipBoundingBox(aContext);
    if (CGRectIntersectsRect(self.bounds, dirtyRect))
    {
        CGContextSetTextMatrix(aContext, CGAffineTransformIdentity);
        CGContextTranslateCTM(aContext, 0.0f, self.bounds.size.height);
        CGContextScaleCTM(aContext, 1.0f, -1.0f);
        CGContextSetShouldAntialias(aContext, YES);
        CGContextSetAllowsAntialiasing(aContext, YES);
        CGContextSetShadowWithColor(aContext, self.stringShadowOffset, self.stringShadowRadius, self.stringShadowColor);
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[self _attributedString]);
        if (framesetter != NULL)
        {
            CGMutablePathRef framePath = CGPathCreateMutable();
            CGPathAddRect(framePath, NULL, CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height));
            CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, NULL);
            if (frame != NULL)
            {
                CTFrameDraw(frame, aContext);
                CFRelease(frame);
            }
            CFRelease(framePath);
            CFRelease(framesetter);
        }
    }
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGSize preferredFrameSize = CGSizeMake(0.0f, 0.0f);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[self _attributedString]);
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
    return CGSizeMake(ceilf(preferredFrameSize.width), ceilf(preferredFrameSize.height)) ;
}

- (BOOL)contentsAreFlipped
{
    return YES;
}

@end
