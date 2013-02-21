//
//  NSColor+CGColor.h
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (WL_CGColor)

+ (NSColor *)WL_colorWithCGColor:(CGColorRef)aCGColor;

- (CGColorRef)WL_CGColor __attribute__((cf_returns_retained));

@end
