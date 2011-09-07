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
 @classdesign One of superlayers must be flipped (that is, geometryFlipped is set to YES).
 */
@interface WLCalendarEventLayer : WLCalendarLayer {
    CGFloat _cachedMinimalHeight;
    BOOL _shouldUpdateMinimalHeightCache;
}

@property (copy) NSAttributedString *title;

@property (copy) NSAttributedString *location;

+ (CGFloat)minimalHumanVisibleWidth;

/*!
 @abstract Returns height that layer should have to fit all lines when width is equal to th aWidth.
 */
- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

/*!
 @abstract Returns height that layer should have to fit at least 1 line.
 */
- (CGFloat)minimalHumanVisibleHeight;


- (void)_drawBackground:(CGContextRef)aContext;

- (void)_drawString:(CGContextRef)aContext;

- (CGSize)_preferredTitleSize;

- (CGSize)_preferredLocationSize;

- (CGFloat)_preferredTitleHeightWithWidth:(CGFloat)aWidth;

- (CGFloat)_preferredLocationHeightWithWidth:(CGFloat)aWidth;

- (void)_drawString:(NSAttributedString *)aString inContext:(CGContextRef)aContext rect:(CGRect)aRect;

@end
