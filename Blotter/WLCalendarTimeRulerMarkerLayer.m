//
//  WLCalendarTextLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarTimeRulerMarkerLayer.h"
#import "NSColor+WLCalendar.h"


@implementation WLCalendarTimeRulerMarkerLayer


#pragma mark Properties
@dynamic marker;


#pragma mark CALayer;

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"string"])
        return YES;
    else if ([aKey isEqualToString:@"contentsScale"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGContextSetTextMatrix(aContext, CGAffineTransformIdentity);
    CGContextTranslateCTM(aContext, 0.0f, self.bounds.size.height);
    CGContextScaleCTM(aContext, 1.0f, -1.0f);
    CGContextSetShouldAntialias(aContext, YES);
    CGContextSetAllowsAntialiasing(aContext, YES);
    CGContextSetAllowsFontSubpixelQuantization(aContext, NO);
    CGContextSetAllowsFontSmoothing(aContext, NO);
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0f, -1.0f), 0.0f, [[NSColor WL_timelineShadowColor] WL_CGColor]);
    else
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0f, 1.0f), 0.0f, [[NSColor WL_timelineShadowColor] WL_CGColor]);
    [self.marker WL_drawWithRect:self.bounds context:aContext];
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    return [self.marker WL_preferredSize];
}

@end
