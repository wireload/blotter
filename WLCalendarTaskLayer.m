//
//  WLCalendarTaskLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTaskLayer.h"
#import "NSColor+CGColor.h"
#import "CATextLayer+WLStringSize.h"
#import "NSColor+WLCalendar.h"


static NSString* const _WLMarkLayerName = @"mark";

static NSString* const _WLTextLayerName = @"text";


static const CGFloat _WLMarkTailIndent = 6.0f;


@implementation WLCalendarTaskLayer

- (id)init
{
    self = [super init];
    if (self != nil) {
        CATextLayer *mark = [CATextLayer layer];
        mark.name = _WLMarkLayerName;
        mark.string = @"•";
        mark.foregroundColor = (CGColorRef)[[self class] defaultValueForKey:@"markColor"];
        mark.fontSize = [[[self class] defaultValueForKey:@"fontSize"] floatValue];
        mark.font = [[self class] defaultValueForKey:@"font"];
        mark.alignmentMode = kCAAlignmentRight;
#ifdef DEBUG_LAYERS
        mark.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
        [self addSublayer:mark];
        [self setValue:mark forKey:_WLMarkLayerName];

        CATextLayer *text = [CATextLayer layer];
        text.name = _WLTextLayerName;
        text.wrapped = YES;
        text.foregroundColor = (CGColorRef)[[self class] defaultValueForKey:@"markColor"];
        text.fontSize = [[[self class] defaultValueForKey:@"fontSize"] floatValue];
        text.font = [[self class] defaultValueForKey:@"font"];
        text.shadowColor = [[NSColor WL_tasksShadowColor] WL_CGColor];
        text.shadowOffset = CGSizeMake(0.0f, -1.0f);
        text.shadowOpacity = 1.0f;
        text.shadowRadius = 0.0f;
#ifdef DEBUG_LAYERS
        text.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
        [self addSublayer:text];
        [self setValue:text forKey:_WLTextLayerName];
    }
    return self;
}


#pragma mark Properties
@dynamic string;
@dynamic stringColor;
@dynamic markColor;
@dynamic font;
@dynamic fontSize;

- (NSString *)string
{
    return [[self valueForKey:_WLTextLayerName] string];
}

- (void)setString:(NSString *)newString
{
    [[self valueForKey:_WLTextLayerName] setString:newString];
}

- (CGColorRef)stringColor
{
    return [(CATextLayer *)[self valueForKey:_WLTextLayerName] foregroundColor];
}

- (void)setStringColor:(CGColorRef)newStringColor
{
    [(CATextLayer *)[self valueForKey:_WLTextLayerName] setForegroundColor:newStringColor];
}

- (CGColorRef)markColor
{
    return [(CATextLayer *)[self valueForKey:_WLMarkLayerName] foregroundColor];
}

- (void)setMarkColor:(CGColorRef)newMarkColor
{
    [(CATextLayer *)[self valueForKey:_WLMarkLayerName] setForegroundColor:newMarkColor];
}

- (CFTypeRef)font
{
    return [[self valueForKey:_WLTextLayerName] font];
}

- (void)setFont:(CFTypeRef)newFont
{
    [[self valueForKey:_WLTextLayerName] setFont:newFont];
    [[self valueForKey:_WLMarkLayerName] setFont:newFont];
}

- (CGFloat)fontSize
{
    return [[self valueForKey:_WLTextLayerName] fontSize];
}

- (void)setFontSize:(CGFloat)newFontSize
{
    [[self valueForKey:_WLTextLayerName] setFontSize:newFontSize];
    [[self valueForKey:_WLMarkLayerName] setFontSize:newFontSize];
}

#pragma mark CALayer

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"markColor"])
        return (id)[[NSColor whiteColor] WL_CGColor];
    else if ([aKey isEqualToString:@"stringColor"] || [aKey isEqualToString:@"markColor"])
        return [CATextLayer defaultValueForKey:@"foregroundColor"];
    else if ([aKey isEqualToString:@"font"])
        return [NSFont fontWithName:@"Helvetica" size:16.0f];
    else if ([aKey isEqualToString:@"fontSize"])
        return [NSNumber numberWithFloat:16.0f];
    else
        return [super defaultValueForKey:aKey];
}

- (void)layoutSublayers
{
    CATextLayer *mark = [self valueForKey:_WLMarkLayerName];
    CGSize preferredSize = [mark preferredFrameSize];
    mark.frame = CGRectIntegral(CGRectMake(0.0f,
                                           0.0f,
                                           preferredSize.width,
                                           self.bounds.size.height));

    CATextLayer *text = [self valueForKey:_WLTextLayerName];
    text.frame = CGRectIntegral(CGRectMake(CGRectGetMaxX(mark.frame) + _WLMarkTailIndent,
                                           0.0f,
                                           self.bounds.size.width - CGRectGetMaxX(mark.frame) - _WLMarkTailIndent,
                                           self.bounds.size.height));
}

- (CGSize)preferredFrameSize
{
    CATextLayer *text = [self valueForKey:_WLTextLayerName];
    CGSize preferredSize = [text preferredFrameSize];
    CATextLayer *mark = [self valueForKey:_WLMarkLayerName];
    preferredSize.width += mark.bounds.size.width + _WLMarkTailIndent;
    return preferredSize;
}

- (CGFloat)maxHeightForWidth:(CGFloat)aWidth
{
    CATextLayer *text = [self valueForKey:_WLTextLayerName];
    CATextLayer *mark = [self valueForKey:_WLMarkLayerName];
    CGFloat markHeight = [mark WL_maxStringHeightForWidth:aWidth];
    CGFloat textHeight = [text WL_maxStringHeightForWidth:aWidth - mark.bounds.size.width - _WLMarkTailIndent];
    return fmaxf(markHeight, textHeight);
}

@end
