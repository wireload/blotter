//
//  WLCalendarTaskLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface WLCalendarTaskLayer : CALayer

@property (copy) NSAttributedString *mark;

@property (copy) NSAttributedString *title;


/*!
 @abstract Returns height that layer should have to fit all lines when width is equal to aWidth.
 */
- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

/*!
 @abstract Returns height that layer should have to fit at least 1 line.
 */
- (CGFloat)minimumHumanVisibleHeight;


- (CGRect)_titleFrame;

- (CGRect)_markFrame;

@end


@interface NSAttributedString (WLCalendarTaskLayer)

/*!
 @discussion    Returns nil if aString is empty.
 */
+ (NSAttributedString *)WL_taskTitleWithString:(NSString *)aString;

/*!
 @discussion    Returns nil if aColor is NULL.
 */
+ (NSAttributedString *)WL_taskMarkWithColor:(CGColorRef)aColor;

@end
