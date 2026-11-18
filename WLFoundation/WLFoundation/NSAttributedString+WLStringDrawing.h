//
//  NSAttributedString.h
//  Blotter
//
//  Created by Ilya Kulakov on 21.09.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


@interface NSAttributedString (WLStringDrawing)

- (void)WL_drawWithRect:(CGRect)aRect context:(CGContextRef)aContext;

- (CGSize)WL_preferredSize;

- (CGFloat)WL_preferredHeightWithWidth:(CGFloat)aWidth;

- (CGFloat)WL_firstLineHeightWithWidth:(CGFloat)aWidth;

- (CGFloat)WL_firstLineHeight;

@end
