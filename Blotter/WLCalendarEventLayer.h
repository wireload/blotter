//
//  WLCalendarEventLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarLayer.h"

/*!
 @classdesign One of superlayers must be flipped (that is, geometryFlipped is set to YES) so the origin would be top left.
 */
@interface WLCalendarEventLayer : WLCalendarLayer {
    CGFloat _cachedMinimumHeight;
    BOOL _shouldUpdateMinimumHeightCache;
}

@property (copy) NSAttributedString *title;

@property (copy) NSAttributedString *location;

/*!
 @abstract      Specifies whether layer should try to keep its text (title and location) visible.
 @discussion    Default value is NO.
 If set to YES, while drawing content uses visibleRect to determine frames of title and location to keep them visible.
 */
@property BOOL keepTextVisible;

+ (CGFloat)minimumHumanVisibleWidth;

/*!
 @abstract Returns height that layer should have to fit all lines when width is equal to aWidth.
 */
- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

/*!
 @abstract Returns height that layer should have to fit at least 1 line.
 */
- (CGFloat)minimumHumanVisibleHeight;


- (void)_drawBackground:(CGContextRef)aContext;

- (void)_drawString:(CGContextRef)aContext;

- (CGColorRef)_lineColor;

@end
