//
//  WLCalendarTextLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface WLCalendarTextLayer : CALayer

@property (copy) NSString *string;

@property CTFontRef font;

@property CGColorRef foregroundColor;

@property CGSize stringShadowOffset;

@property CGColorRef stringShadowColor;

@property CGFloat stringShadowRadius;


- (NSAttributedString *)_attributedString;

@end
