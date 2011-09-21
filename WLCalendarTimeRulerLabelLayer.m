//
//  WLCalendarTextLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTimeRulerLabelLayer.h"
#import "NSColor+CGColor.h"
#import "NSColor+WLCalendar.h"
#import "NSAttributedString+WLStringDrawing.h"


@implementation WLCalendarTimeRulerLabelLayer


#pragma mark Properties
@dynamic string;


#pragma mark CALayer;

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"string"])
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
        CGContextSetAllowsFontSubpixelQuantization(aContext, NO);
        CGContextSetAllowsFontSmoothing(aContext, NO);
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0f, 1.0f), 0.0f, [[NSColor WL_timelineShadowColor] WL_CGColor]);
        [self.string WL_drawWithRect:self.bounds context:aContext];
    }
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    return [self.string WL_preferredSize];
}

@end
