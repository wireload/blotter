//
//  WLCalendarReminderLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalendarReminderLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static const CGFloat _WLMarkTailIndent = 6.0;


@implementation WLCalendarReminderLayer

#pragma mark Properties
@dynamic mark;
@dynamic title;


#pragma mark Methods

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGSize markSize = [self.mark WL_preferredSize];
    CGFloat width = fdim(aWidth, markSize.width + _WLMarkTailIndent);
    return fmax([self.title WL_preferredHeightWithWidth:width],
                [self.mark WL_preferredSize].height);
}

- (CGFloat)minimumHumanVisibleHeight
{
    CGSize markSize = [self.mark WL_preferredSize];
    CGFloat titleWidth = fdim(CGRectGetWidth(self.bounds), markSize.width + _WLMarkTailIndent);
    return fmax([self.mark WL_firstLineHeightWithWidth:CGRectGetWidth(self.bounds)],
                [self.title WL_firstLineHeightWithWidth:titleWidth]);
}


#pragma mark Private

- (CGRect)_titleFrame
{
    CGRect markFrame = [self _markFrame];
    return CGRectIntegral(CGRectMake(CGRectGetMaxX(markFrame) + _WLMarkTailIndent,
                                     0.0,
                                     fdim(CGRectGetWidth(self.bounds), CGRectGetMaxX(markFrame) + _WLMarkTailIndent),
                                     CGRectGetHeight(self.bounds)));
}

- (CGRect)_markFrame
{
    CGSize preferredSize = [self.mark WL_preferredSize];
    CGFloat topMargin = -1.0;

    if ([self contentsAreFlipped])
    {
        return CGRectIntegral(CGRectMake(0.0,
                                         0.0,
                                         preferredSize.width,
                                         fdim(CGRectGetHeight(self.bounds), topMargin)));
    }
    else
    {
        return CGRectIntegral(CGRectMake(0.0,
                                         topMargin,
                                         preferredSize.width,
                                         fdim(CGRectGetHeight(self.bounds), topMargin)));
    }
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"])
        return YES;
    else if ([aKey isEqualToString:@"mark"])
        return YES;
    else if ([aKey isEqualToString:@"contentsScale"])
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

    if ([self contentsAreFlipped])
    {
        CGAffineTransform flipVertical = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, CGRectGetHeight(self.bounds));
        CGContextConcatCTM(aContext, flipVertical);
    }

#ifdef DEBUG_LAYERS
    CGContextSetFillColorWithColor(aContext, [[NSColor greenColor] WL_CGColor]);
    CGContextFillRect(aContext, [self _markFrame]);
    CGContextFillRect(aContext, [self _titleFrame]);
#endif

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6 || ![self contentsAreFlipped])
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, 1.0), 0.0, [[[NSColor whiteColor] colorWithAlphaComponent:0.25] WL_CGColor]);
    else
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, -1.0), 0.0, [[[NSColor whiteColor] colorWithAlphaComponent:0.25] WL_CGColor]);

    [self.mark WL_drawWithRect:[self _markFrame] context:aContext];

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6 || ![self contentsAreFlipped])
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, -1.0), 0.0, [[NSColor WL_taskTextShadowColor] WL_CGColor]);
    else
        CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, 1.0), 0.0, [[NSColor WL_taskTextShadowColor] WL_CGColor]);

    [self.mark WL_drawWithRect:[self _markFrame] context:aContext];
    [self.title WL_drawWithRect:[self _titleFrame] context:aContext];

    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    CGSize titleSize = [self.title WL_preferredSize];
    CGSize markSize = [self.mark WL_preferredSize];
    return CGSizeMake(markSize.width + _WLMarkTailIndent + titleSize.width,
                      fmax(titleSize.height, markSize.height));
}

@end


@implementation NSAttributedString (WLCalendarReminderLayer)

+ (NSAttributedString *)WL_reminderTitleWithString:(NSString *)aString
{
    if ([aString length] == 0)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *TitleAttributes = nil;
    dispatch_once(&onceToken, ^{
        TitleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
                           (id)[[NSColor WL_taskTitleColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
                           nil];
    });
    return [[NSAttributedString alloc] initWithString:[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                           attributes:TitleAttributes];
}

+ (NSAttributedString *)WL_reminderMarkWithColor:(CGColorRef)aColor
{
    if(aColor == NULL)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *MarkAttributes = nil;
    dispatch_once(&onceToken, ^{
        MarkAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                          (id)[NSFont WL_taskFont],                      (id)kCTFontAttributeName,
                          nil];
    });
    NSMutableDictionary *a = [MarkAttributes mutableCopy];
    [a setObject:(__bridge NSColor *)aColor forKey:(id)kCTForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"●", @"Task's mark")
                                           attributes:a];
}

@end
