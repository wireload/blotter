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
}

@property (copy) NSAttributedString *string;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

- (CGFloat)minimalHumanVisibleHeight;

+ (CGFloat)minimalHumanVisibleWidth;

@end
