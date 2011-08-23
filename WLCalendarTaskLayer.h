//
//  WLCalendarTaskLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface WLCalendarTaskLayer : CALayer

@property (nonatomic, copy) NSString *string;

@property (nonatomic) CGColorRef stringColor;

@property (nonatomic) CGColorRef markColor;

@property (nonatomic) CFTypeRef font;

@property (nonatomic) CGFloat fontSize;

- (CGFloat)maxHeightForWidth:(CGFloat)aWidth;

@end
