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
#ifndef DEBUG_LAYERS
    CGRect layerBounds = self.bounds;

    CGContextSaveGState(aContext);

    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    CGContextSetFillColorWithColor(aContext, backgroundColor);
    CGContextFillRect(aContext, layerBounds);
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
                                layerBounds.origin,
                                CGPointMake(CGRectGetMinX(layerBounds), CGRectGetMaxY(layerBounds)),
                                kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(transparentToWhite);
    CGContextRestoreGState(aContext);

    CGContextRestoreGState(aContext);
#endif
}

@end
