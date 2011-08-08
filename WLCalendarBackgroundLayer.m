//
//  WLCalendarBackgroundLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarBackgroundLayer.h"


@implementation WLCalendarBackgroundLayer

- (void)drawInContext:(CGContextRef)aContext
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    CGContextSaveGState(aContext);

    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    CGContextSetFillColorWithColor(aContext, backgroundColor);
    CGContextFillRect(aContext, self.bounds);
    CGColorRelease(backgroundColor);

    CGContextSaveGState(aContext);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(self.contentsBackgroundColor);
    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8] = {0.0, 0.0, 0.0, 0.0,
        1.0, 1.0, 1.0, 0.13 * self.contentsBackgroundOpacity};
    CGGradientRef transparentToWhite = CGGradientCreateWithColorComponents(colorSpace,
                                                                           components,
                                                                           locations,
                                                                           sizeof(locations) / sizeof(CGFloat));
    CGContextSetBlendMode(aContext, kCGBlendModeOverlay);
    CGContextDrawLinearGradient(aContext,
                                transparentToWhite,
                                self.bounds.origin,
                                CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds)),
                                kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(transparentToWhite);
    CGContextRestoreGState(aContext);

    CGContextRestoreGState(aContext);

}

@end
