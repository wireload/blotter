//
//  WLCalendarEventLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarEventLayer.h"
#import "CATextLayer+WLStringSize.h"
#import "NSColor+CGColor.h"


const CGFloat _WLYPadding = 10.0f;
const CGFloat _WLXPadding = 10.0f;


@implementation WLCalendarEventLayer
@dynamic string;
@dynamic font;
@dynamic fontSize;
@dynamic wrapped;
@dynamic contentsBackgroundOpacity;
@dynamic contentsBackgroundColor;

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentBackgroundAlphaValue"])
        return [NSNumber numberWithFloat:1.0f];
    else if ([aKey isEqualToString:@"contentBackgroundColor"])
        return [NSColor clearColor];
    else
        return [super defaultValueForKey:aKey];
}

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentBackgroundAlphaValue"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [CATransaction setDisableActions:YES];
        self.masksToBounds = YES;
        [CATransaction setDisableActions:NO];
        _textLayer = [CATextLayer layer];
        _textLayer.wrapped = YES;
        _textLayer.truncationMode = kCATruncationEnd;
        //_textLayer.font = [NSFont userFontOfSize:12.0f];
        _textLayer.fontSize = 12.0f;
        _textLayer.shadowOpacity = 1.0f;
        _textLayer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        _textLayer.shadowRadius = 1.0f;
#ifdef DEBUG_LAYERS
        _textLayer.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
        [self addSublayer:_textLayer];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)aContext
{
#ifndef DEBUG_LAYERS
    CGRect layerBounds = self.bounds;

    CGContextSaveGState(aContext);

    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    CGContextSetFillColorWithColor(aContext, backgroundColor);
    CGContextFillRect(aContext, layerBounds);
    CGColorRelease(backgroundColor);

    CGContextSaveGState(aContext);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(self.contentsBackgroundColor);
    CGFloat locations[2] = {0.0f, 1.0f};
    CGFloat components[8] = {1.0f, 1.0f, 1.0f, 0.6f * self.contentsBackgroundOpacity,
        0.0f, 0.0f, 0.0f, 0.0f};
    CGGradientRef whiteToTransparent = CGGradientCreateWithColorComponents(colorSpace,
                                                                           components,
                                                                           locations,
                                                                           sizeof(locations) / sizeof(CGFloat));
    CGContextSetBlendMode(aContext, kCGBlendModeOverlay);
    CGContextDrawLinearGradient(aContext,
                                whiteToTransparent,
                                layerBounds.origin,
                                CGPointMake(CGRectGetMinX(layerBounds), CGRectGetMaxY(layerBounds)),
                                kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(whiteToTransparent);
    CGContextRestoreGState(aContext);

    CGContextBeginPath(aContext);
    CGContextMoveToPoint(aContext, layerBounds.origin.x, layerBounds.origin.y);
    CGContextAddLineToPoint(aContext, CGRectGetMaxX(layerBounds), layerBounds.origin.y);
    CGContextMoveToPoint(aContext, layerBounds.origin.x, CGRectGetMaxY(layerBounds));
    CGContextAddLineToPoint(aContext, CGRectGetMaxX(layerBounds), CGRectGetMaxY(layerBounds));
    CGColorRef lineColor = CGColorCreateCopyWithAlpha([[NSColor whiteColor] WL_CGColor], self.contentsBackgroundOpacity);
    CGContextSetStrokeColorWithColor(aContext, lineColor);
    CGContextStrokePath(aContext);
    CGColorRelease(lineColor);

    CGContextRestoreGState(aContext);
#endif
}

- (void)layoutSublayers
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGRect layerBounds = self.bounds;
    CGFloat maxHeight = MIN([_textLayer WL_maxStringHeightForWidth:layerBounds.size.width - _WLXPadding],
                            layerBounds.size.height - _WLYPadding);
    _textLayer.frame = CGRectMake(floorf(CGRectGetMinX(layerBounds) + _WLXPadding / 2),
                                  ceilf(_WLYPadding / 2),
                                  layerBounds.size.width - _WLXPadding,
                                  maxHeight);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGSize preferredTextSize = [_textLayer preferredFrameSize];
    return CGSizeMake(preferredTextSize.width + _WLXPadding, preferredTextSize.height + _WLYPadding);
}

- (id)string
{
    return _textLayer.string;
}

- (void)setString:(id)newString
{
    _textLayer.string = newString;
    [self setNeedsLayout];
}

- (CFTypeRef)font
{
    return _textLayer.font;
}

- (void)setFont:(CFTypeRef)newFont
{
    _textLayer.font = newFont;
}

- (CGFloat)fontSize
{
    return _textLayer.fontSize;
}

- (void)setFontSize:(CGFloat)newFontSize
{
    _textLayer.fontSize = newFontSize;
    [self setNeedsLayout];
}

- (BOOL)wrapped
{
    return _textLayer.wrapped;
}

- (void)setWrapped:(BOOL)newWrapped
{
    _textLayer.wrapped = newWrapped;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGFloat height = [_textLayer WL_maxStringHeightForWidth:aWidth + _WLXPadding];
    return height + _WLXPadding;
}

- (CGFloat)minimalHumanVisibleHeight
{
    // TODO: calculate height from current font size and y padding.
    return 20.0f;
}

+ (CGFloat)minimalHumanVisibleWidth
{
    return _WLXPadding + 30.0f;
}

@end
