//
//  NSColor+CGColor.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSColor+CGColor.h"


@implementation NSColor(WL_CGColor)

+ (NSColor *)WL_NSColorFromCGColor:(CGColorRef)cgColor
{
    NSColorSpace *colorSpace = [[[NSColorSpace alloc] initWithCGColorSpace:CGColorGetColorSpace(cgColor)] autorelease];
    size_t numberOfComponents = CGColorGetNumberOfComponents(cgColor);
    const CGFloat *components = CGColorGetComponents(cgColor);
    return [NSColor colorWithColorSpace:colorSpace components:components count:numberOfComponents];
}

- (CGColorRef)WL_CGColor {
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    NSInteger componentCount = [self numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return (CGColorRef)[(id)color autorelease];
}

@end
