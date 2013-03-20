//
//  NSColor+CGColor.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "NSColor+CGColor.h"


@implementation NSColor(WL_CGColor)

+ (NSColor *)WL_fastColorWithCGColor:(CGColorRef)aCGColor
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7)
        return [self colorWithCGColor:aCGColor];
    else
        return nil;
}

+ (NSColor *)WL_slowColorWithCGColor:(CGColorRef)aCGColor
{
    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:CGColorGetColorSpace(aCGColor)] ;
    size_t numberOfComponents = CGColorGetNumberOfComponents(aCGColor);
    const CGFloat *components = CGColorGetComponents(aCGColor);
    NSParameterAssert(numberOfComponents < NSIntegerMax);
    return [NSColor colorWithColorSpace:colorSpace components:components count:(NSInteger)numberOfComponents];
}

+ (NSColor *)WL_colorWithCGColor:(CGColorRef)aCGColor
{
    NSColor *color = [self WL_fastColorWithCGColor:aCGColor];

    if (!color)
        color = [self WL_slowColorWithCGColor:aCGColor];

    return color;
}

- (CGColorRef)WL_fastCGColor
{
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7)
        return [self CGColor];
    else
        return nil;
}

- (CGColorRef)WL_slowCGColor __attribute__((cf_returns_retained))
{
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    CGColorSpaceRetain(colorSpace);

    if (colorSpace == NULL)
        colorSpace = CGColorSpaceCreateDeviceRGB();

    NSInteger componentCount = [self numberOfComponents];
    NSParameterAssert(componentCount > 0);
    CGFloat *components = (CGFloat *)calloc((size_t)componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    CGColorSpaceRelease(colorSpace);

    return color;
}

- (CGColorRef)WL_CGColor
{
    CGColorRef CGColor = CGColorRetain([self WL_fastCGColor]);

    if (!CGColor)
        CGColor = [self WL_slowCGColor];

    return CGColor;
}

@end
