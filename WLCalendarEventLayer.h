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


@interface WLCalendarEventLayer : WLCalendarLayer {
    CATextLayer *_textLayer;
}

@property (copy) id string;

@property CFTypeRef font;

@property CGFloat fontSize;

@property BOOL wrapped;

@property CGFloat contentsBackgroundOpacity;

@property CGColorRef contentsBackgroundColor;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

- (CGFloat)minimalHumanVisibleHeight;

+ (CGFloat)minimalHumanVisibleWidth;

@end
