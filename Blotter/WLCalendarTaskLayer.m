//
//  WLCalendarTaskLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarTaskLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static const CGFloat _WLMarkTailIndent = 6.0f;


@implementation WLCalendarTaskLayer


#pragma mark Properties
@dynamic mark;
@dynamic title;


#pragma mark Methods

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGSize markSize = [self.mark WL_preferredSize];
    return fmaxf([self.title WL_preferredHeightWithWidth:aWidth - markSize.width - _WLMarkTailIndent],
                 [self.mark WL_preferredSize].height);
}

- (CGFloat)minimumHumanVisibleHeight
{
    CGSize markSize = [self.mark WL_preferredSize];
    return fmaxf([self.mark WL_firstLineHeightWithWidth:self.bounds.size.width],
                 [self.title WL_firstLineHeightWithWidth:self.bounds.size.width - markSize.width - _WLMarkTailIndent]);
}


#pragma mark Private

- (CGRect)_titleFrame
{
    CGRect markFrame = [self _markFrame];
    return CGRectIntegral(CGRectMake(CGRectGetMaxX(markFrame) + _WLMarkTailIndent,
                                     0.0f,
                                     self.bounds.size.width - CGRectGetMaxX(markFrame) - _WLMarkTailIndent,
                                     self.bounds.size.height));
}

- (CGRect)_markFrame
{
    CGSize preferredSize = [self.mark WL_preferredSize];
    return CGRectIntegral(CGRectMake(0.0f,
                                     2.0f,
                                     preferredSize.width,
                                     self.bounds.size.height));
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"])
        return YES;
    else if ([aKey isEqualToString:@"mark"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGContextSetShouldAntialias(aContext, YES);
    CGContextSetAllowsAntialiasing(aContext, YES);
    CGContextSetAllowsFontSubpixelQuantization(aContext, NO);
    CGContextSetAllowsFontSmoothing(aContext, NO);

    CGContextSetShadowWithColor(aContext, CGSizeMake(0.0f, 1.0f), 0.0f, [[[NSColor whiteColor] colorWithAlphaComponent:0.25] WL_CGColor]);
    [self.mark WL_drawWithRect:[self _markFrame] context:aContext];
    
    CGContextSetShadowWithColor(aContext, CGSizeMake(0.0f, -1.0f), 0.0f, [[NSColor WL_taskTextShadowColor] WL_CGColor]);

    [self.mark WL_drawWithRect:[self _markFrame] context:aContext];
    [self.title WL_drawWithRect:[self _titleFrame] context:aContext];

    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    CGSize titleSize = [self.title WL_preferredSize];
    CGSize markSize = [self.mark WL_preferredSize];
    return CGSizeMake(markSize.width + _WLMarkTailIndent + titleSize.width,
                      fmaxf(titleSize.height, markSize.height));
}

@end
