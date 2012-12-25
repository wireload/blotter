//
//  WLCalendarEventLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 15.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarEventLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


const CGFloat _WLYPadding = 6.0;

const CGFloat _WLXPadding = 10.0;

const CGFloat _WLMinimumStringWidth = 10.0; // Width of "..." for the current event title/location attributes.

const CGFloat _WLMinimumStringHeight = 5.0;


@implementation WLCalendarEventLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
    }
    return self;
}

- (void)dealloc
{
    [_cachedVisibleString release];
    [_cachedLocation release];
    [_cachedTitle release];
    [super dealloc];
}

#pragma mark Properties
@dynamic title;
@dynamic location;
@dynamic keepsTextVisible;
@dynamic contentsBackgroundOpacity;
@dynamic contentsBackgroundColor;

- (void)setCornerRadius:(CGFloat)newCornerRadius
{
    if (newCornerRadius == 0.0)
        self.borderWidth = 0.0;
    else
    {
        self.borderColor = [self _lineColor];
        self.borderWidth = 1.0;
    }
    [super setCornerRadius:newCornerRadius];
}


#pragma mark Methods

+ (CGFloat)minimumHumanVisibleWidth
{
    // At least 2 side-by-side events should be visible on 1280x800.
    // Width of column depends on user's locale. The widest locale is South Korea.
    // return _WLXPadding + 20.0;

    // ...actually overlapping events look like a bug because their colours and text
    // mix. It's better to keep trying to render them side by side, no matter how
    // small.
    return 1.0;
}

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    return [self.title WL_preferredHeightWithWidth:fdim(aWidth, _WLXPadding)] + [self.location WL_preferredHeightWithWidth:fdim(aWidth, _WLXPadding)] + _WLYPadding;
}

- (CGFloat)minimumHumanVisibleHeight
{
    NSAttributedString *visibleString = [self.title length] > 0 ? self.title : self.location;
    if (![visibleString isEqualToAttributedString:_cachedVisibleString])
    {
        [visibleString retain];
        [_cachedVisibleString release];
        _cachedVisibleString = visibleString;

        if (_cachedVisibleString != nil)
            _cachedMinimumHumanVisibleHeight = [visibleString WL_firstLineHeight] + _WLYPadding;
        else
            _cachedMinimumHumanVisibleHeight = _WLYPadding;
    }
    return _cachedMinimumHumanVisibleHeight;
}

- (CGFloat)minimumHumanVisibleHeightWithWidth:(CGFloat)aWidth
{
    NSAttributedString *visibleString = [self.title length] > 0 ? self.title : self.location;
    return [visibleString WL_firstLineHeightWithWidth:fdim(aWidth, _WLXPadding)] + _WLYPadding;
}


#pragma mark Private

- (void)_drawBackground:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);
    CGColorRef backgroundColor = CGColorCreateCopyWithAlpha(self.contentsBackgroundColor, self.contentsBackgroundOpacity);
    NSColor *nsBackgroundColor = [[NSColor WL_colorWithCGColor:backgroundColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    nsBackgroundColor = [NSColor colorWithCalibratedHue:[nsBackgroundColor hueComponent]
                                             saturation:fmin(1.0, [nsBackgroundColor saturationComponent] * 1.05)
                                             brightness:fmin(1.0, [nsBackgroundColor brightnessComponent] * 1.05)
                                                  alpha:self.contentsBackgroundOpacity];
    CGContextSetFillColorWithColor(aContext, [nsBackgroundColor WL_CGColor]);
    CGContextFillRect(aContext, self.bounds);
    CGColorRelease(backgroundColor);

    CGContextSaveGState(aContext);
    CGColorSpaceRef colorSpace = CGColorGetColorSpace(self.contentsBackgroundColor);
    static const CGFloat WhiteToTransparentGradientLocations[2] = {0.0, 1.0};
    static const CGFloat WhiteToTransparentGradientComponents[8] = {
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.15
    };
    CGGradientRef whiteToTransparent = CGGradientCreateWithColorComponents(colorSpace,
                                                                           WhiteToTransparentGradientComponents,
                                                                           WhiteToTransparentGradientLocations,
                                                                           sizeof(WhiteToTransparentGradientLocations) / sizeof(CGFloat));
    CGContextSetBlendMode(aContext, kCGBlendModeMultiply);
    CGContextDrawLinearGradient(aContext,
                                whiteToTransparent,
                                self.bounds.origin,
                                CGPointMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds)),
                                kCGGradientDrawsBeforeStartLocation);
    CGGradientRelease(whiteToTransparent);
    CGContextRestoreGState(aContext);


    if (self.cornerRadius == 0.0)
    {
        self.borderWidth = 0.0;
        CGContextSetLineWidth(aContext, 1.0);
        CGContextSetShouldAntialias(aContext, NO);
        CGContextSetStrokeColorWithColor(aContext, [self _lineColor]);
        CGContextBeginPath(aContext);
        CGContextMoveToPoint(aContext, CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds) + 1.0 * 0.5);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMinY(self.bounds) + 1.0 * 0.5);
        CGContextMoveToPoint(aContext, CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - 1.0 * 0.5);
        CGContextAddLineToPoint(aContext, CGRectGetMaxX(self.bounds), CGRectGetMaxY(self.bounds) - 1.0 * 0.5);
        CGContextStrokePath(aContext);
    }
    CGContextRestoreGState(aContext);
}

- (void)_drawString:(CGContextRef)aContext
{
    if ([self.title length] == 0 && [self.location length] == 0)
        return;

    if (IS_LESS_CGFLOAT(fdim(CGRectGetHeight(self.bounds), _WLYPadding), _WLMinimumStringHeight) || IS_LESS_CGFLOAT(fdim(CGRectGetWidth(self.bounds), _WLXPadding), _WLMinimumStringWidth))
        return;

    CGContextSaveGState(aContext);
    CGRect titleAndLocationFrame = CGRectInset(self.bounds, _WLXPadding / 2.0, _WLYPadding / 2.0);
    CGRect dirtyRect = CGContextGetClipBoundingBox(aContext);
    if (CGRectIntersectsRect(titleAndLocationFrame, dirtyRect))
    {
        CGContextSetTextMatrix(aContext, CGAffineTransformIdentity);
        CGContextTranslateCTM(aContext, 0.0, self.bounds.size.height);
        CGContextScaleCTM(aContext, 1.0, -1.0);
        CGContextSetShouldSmoothFonts(aContext, YES);
        CGContextSetAllowsFontSmoothing(aContext, YES);
        CGContextSetShouldAntialias(aContext, YES);
        CGContextSetAllowsAntialiasing(aContext, YES);
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, -1.0), 0.0, [[NSColor WL_eventTextShadowColor] WL_CGColor]);
        else
            CGContextSetShadowWithColor(aContext, CGSizeMake(0.0, 1.0), 0.0, [[NSColor WL_eventTextShadowColor] WL_CGColor]);

        CGFloat preferredTitleHeight = [self.title WL_preferredHeightWithWidth:fdim(CGRectGetWidth(self.bounds), _WLXPadding)];
        if (preferredTitleHeight < titleAndLocationFrame.size.height)
        {
            CGFloat titleHeight = preferredTitleHeight;
            CGFloat preferredLocationHeight = [self.location WL_preferredHeightWithWidth:fdim(CGRectGetWidth(self.bounds), _WLXPadding)];
            CGFloat locationHeight = CGFLOAT_MAX;
            if (preferredTitleHeight + preferredLocationHeight < titleAndLocationFrame.size.height)
            {
                locationHeight = preferredLocationHeight;
                if (self.keepsTextVisible)
                {
                    // Make text visible as much as possible.
                    // Visible rect's origin is top left, while context's origin is bottom left. Convert to context's coordinates.
                    CGFloat visibleRectTop = fdim(CGRectGetHeight(self.bounds), CGRectGetMinY(self.visibleRect));
                    CGFloat visibleRectBottom = fdim(CGRectGetHeight(self.bounds), CGRectGetMaxY(self.visibleRect));
                    CGFloat maxY = fdim(CGRectGetMaxY(titleAndLocationFrame), titleHeight + locationHeight);
                    CGFloat minY = CGRectGetMinY(titleAndLocationFrame);
                    // If the parent layer fits the whole event layer, draw text as usual, otherwise center it.
                    CGFloat y = 0.0;
                    BOOL isWholeEventLayerVisible = (visibleRectTop >= maxY && visibleRectBottom <= minY);
                    BOOL isEventLayerBecomeVisible = (visibleRectTop >= maxY && visibleRectBottom > minY);
                    if (isWholeEventLayerVisible || isEventLayerBecomeVisible)
                    {
                        y = fdim(visibleRectTop, titleHeight + locationHeight);
                        y = fmin(maxY, fmax(minY, y));
                    }
                    else
                    {
                        y = visibleRectBottom + ((visibleRectTop - visibleRectBottom) - (titleHeight + locationHeight)) / 2.0;
                        y = fmin(maxY, fmax(minY, y));
                    }
                    titleAndLocationFrame.origin.y = y;
                    titleAndLocationFrame.size.height = titleHeight + locationHeight;
                }
            }
            else
                locationHeight = fdim(CGRectGetHeight(titleAndLocationFrame), titleHeight);

            CGRect titleFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                          fdim(CGRectGetMaxY(titleAndLocationFrame), titleHeight),
                                                          titleAndLocationFrame.size.width,
                                                          titleHeight));
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[NSColor greenColor] WL_CGColor]);
            CGContextFillRect(aContext, titleFrame);
#endif
            [self.title WL_drawWithRect:titleFrame context:aContext];
            CGRect locationFrame = CGRectIntegral(CGRectMake(titleAndLocationFrame.origin.x,
                                                             fdim(CGRectGetMinY(titleFrame), locationHeight),
                                                             titleAndLocationFrame.size.width,
                                                             locationHeight));
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[[NSColor greenColor] colorWithAlphaComponent:0.8] WL_CGColor]);
            CGContextFillRect(aContext, locationFrame);
#endif
            [self.location WL_drawWithRect:locationFrame context:aContext];
        }
        else
        {
#ifdef DEBUG_LAYERS
            CGContextSetFillColorWithColor(aContext, [[[NSColor greenColor] colorWithAlphaComponent:0.3] WL_CGColor]);
            CGContextFillRect(aContext, titleAndLocationFrame);
#endif
            // Layer cannot fit title, so there is no need to draw location.
            [self.title WL_drawWithRect:titleAndLocationFrame context:aContext];
        }
    }
    CGContextRestoreGState(aContext);
}

- (CGColorRef)_lineColor
{
    CGColorRef lineColor = CGColorCreateCopyWithAlpha([[NSColor whiteColor] WL_CGColor], 0.25);
    return (CGColorRef)[(id)lineColor autorelease];
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"title"])
        return YES;
    else if ([aKey isEqualToString:@"location"])
        return YES;
    else if ([aKey isEqualToString:@"keepsTextVisible"])
        return YES;
    else if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return YES;
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return YES;
    else if ([aKey isEqualToString:@"contentsScale"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey {
    if ([aKey isEqualToString:@"keepsTextVisible"])
        return [NSNumber numberWithBool:NO];
    else if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [NSNumber numberWithFloat:1.0];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return (id)[[NSColor clearColor] WL_CGColor];
    else
        return [super defaultValueForKey:aKey];
}

+ (id<CAAction>)defaultActionForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundOpacity"];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundColor"];
    else
        return [super defaultActionForKey:aKey];
}

- (id<CAAction>)actionForKey:(NSString *)aKey
{
    id<CAAction> action = [super actionForKey:aKey];
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundOpacity"]];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundColor"]];
    return action;
}

- (void)drawInContext:(CGContextRef)aContext
{
    CGContextSaveGState(aContext);

#ifndef DEBUG_LAYERS
    [self _drawBackground:aContext];
#endif

    // It's important to draw background before text to make antialiasing possible.
    [self _drawString:aContext];
    CGContextRestoreGState(aContext);
}

- (CGSize)preferredFrameSize
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    if (![_cachedTitle isEqualToAttributedString:self.title])
    {
        [_cachedTitle release];
        _cachedTitle = [self.title retain];
        _cachedPreferredSizeOfTitle = [_cachedTitle WL_preferredSize];
    }
    if (![_cachedLocation isEqualToAttributedString:self.location])
    {
        [_cachedLocation release];
        _cachedLocation = [self.location retain];
        _cachedPreferredSizeOfLocation = [self.location WL_preferredSize];
    }
    return CGSizeMake(fmax(_cachedPreferredSizeOfTitle.width, _cachedPreferredSizeOfLocation.width) + _WLXPadding,
                      _cachedPreferredSizeOfTitle.height + _cachedPreferredSizeOfLocation.height + _WLYPadding);
}

@end


@implementation NSAttributedString (WLCalendarEventLayer)

+ (NSAttributedString *)WL_eventTitleWithString:(NSString *)aString
{
    if ([aString length] == 0)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *TitleAttributes = nil;
    dispatch_once(&onceToken, ^{
        TitleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           (id)[[NSColor whiteColor] WL_CGColor], (id)kCTForegroundColorAttributeName,
                           (id)[NSFont WL_eventTitleFont],        (id)kCTFontAttributeName,
                           nil];
    });
    return [[[NSAttributedString alloc] initWithString:[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                            attributes:TitleAttributes] autorelease];
}

+ (NSAttributedString *)WL_eventLocationWithString:(NSString *)aString;
{
    if ([aString length] == 0)
        return nil;

    static dispatch_once_t onceToken;
    static NSDictionary *LocationAttributes = nil;
    dispatch_once(&onceToken, ^{
        LocationAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                              (id)[[NSColor WL_eventLocationColor] WL_CGColor], (id)kCTForegroundColorAttributeName,
                              (id)[NSFont WL_eventLocationFont],                (id)kCTFontAttributeName,
                              nil];
    });
    return [[[NSAttributedString alloc] initWithString:[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                                            attributes:LocationAttributes] autorelease];
}

@end
