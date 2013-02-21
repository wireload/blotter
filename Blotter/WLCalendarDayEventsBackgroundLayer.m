//
//  WLCalendarDayEventsBackgroundLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 07/03/2012.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLGraphics.h"
#import "WLCalendarDayEventsBackgroundLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


static const NSStringDrawingOptions _WLTitleDrawingOptions = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine;


@implementation WLCalendarDayEventsBackgroundLayer

- (id)initWithLayer:(id)aLayer
{
    self = [super initWithLayer:aLayer];
    if (self != nil)
    {
        title = [[aLayer title] copy];
        isTitleHighlighted = [aLayer isTitleHighlighted];
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

#pragma mark Properties
@dynamic titleFrame;
@synthesize title;
@synthesize isTitleHighlighted;

- (void)setTitle:(NSString *)newTitle
{
    NSString *tmp = [newTitle copy];
    [title release];
    title = tmp;
    _needsUpdateTitleCache = YES;
    [self setNeedsDisplay];
}

- (void)setIsTitleHighlighted:(BOOL)newIsTitleHighlighted
{
    if (newIsTitleHighlighted != isTitleHighlighted)
    {
        [self willChangeValueForKey:@"isTitleHighlighted"];
        isTitleHighlighted = newIsTitleHighlighted;
        _needsUpdateTitleCache = YES;
        [self setNeedsDisplay];
        [self didChangeValueForKey:@"isTitleHighlighted"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfIsTitleHighlighted
{
    return NO;
}


#pragma mark Methods

- (CGSize)preferredTitleFrameSizeWithBoundingSize:(CGSize)aBoundingSize
{
    if (_needsUpdateTitleCache)
    {
        _titleCache._preferredFrameSizeOut = NSSizeToCGSize([self.title boundingRectWithSize:NSMakeSize(9999.0, 9999.0)
                                                                                     options:_WLTitleDrawingOptions
                                                                                  attributes:self.isTitleHighlighted ? [NSDictionary WL_highlightedTitleAttributes] : [NSDictionary WL_titleAttributes]].size);
    }
    BOOL isBoundingSizeEqualToCachedBoundingSize = CGSizeEqualToSize(aBoundingSize, _titleCache._cachedBoundingSizeIn);
    if (_needsUpdateTitleCache || !isBoundingSizeEqualToCachedBoundingSize)
    {
        BOOL isBoundingSizeContainsPreferredFrameSize = !IS_LESS_CGFLOAT(aBoundingSize.width, _titleCache._preferredFrameSizeOut.width) && !IS_LESS_CGFLOAT(aBoundingSize.height, _titleCache._preferredFrameSizeOut.height);
        if (isBoundingSizeContainsPreferredFrameSize)
            _titleCache._preferredFrameSizeWithinBoundingSizeOut = _titleCache._preferredFrameSizeOut;
        else
        {
            _titleCache._preferredFrameSizeWithinBoundingSizeOut = NSSizeToCGSize([self.title boundingRectWithSize:NSSizeFromCGSize(aBoundingSize)
                                                                                                           options:_WLTitleDrawingOptions
                                                                                                        attributes:self.isTitleHighlighted ? [NSDictionary WL_highlightedTitleAttributes] : [NSDictionary WL_titleAttributes]].size);
        }
    }
    _needsUpdateTitleCache = NO;
    _titleCache._cachedBoundingSizeIn = aBoundingSize;
    return _titleCache._preferredFrameSizeWithinBoundingSizeOut;
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"titleFrame"])
        return YES;
    else if ([aKey isEqualToString:@"title"])
        return NO; // customized property
    else if ([aKey isEqualToString:@"isTitleHighlighted"])
        return NO; // customized property
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"needsDisplayOnBoundsChange"])
        return [NSNumber numberWithBool:YES];
    else
        return [super defaultValueForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    static dispatch_once_t onceToken;
    static NSGradient *WhiteToTransparentGradient = nil;
    dispatch_once(&onceToken, ^{
        WhiteToTransparentGradient = [[NSGradient alloc] initWithStartingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.1]
                                                                   endingColor:[NSColor clearColor]];
    });

    NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[self contentsAreFlipped]];
    [c setImageInterpolation:NSImageInterpolationHigh];
    [c setShouldAntialias:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:c];

    NSRect dirtyRect = NSRectFromCGRect(CGContextGetClipBoundingBox(aContext));
#ifndef DEBUG_LAYERS
    NSRect bounds = [self bounds];

    WLDrawScaledNinePartImage(bounds,
                              [NSImage imageNamed:@"calendar-week-day-top-left"],
                              [NSImage imageNamed:@"calendar-week-day-top-middle"],
                              [NSImage imageNamed:@"calendar-week-day-top-right"],
                              [NSImage imageNamed:@"calendar-week-day-middle-left"],
                              [NSImage imageNamed:@"calendar-week-day-middle-middle"],
                              [NSImage imageNamed:@"calendar-week-day-middle-right"],
                              [NSImage imageNamed:@"calendar-week-day-bottom-left"],
                              [NSImage imageNamed:@"calendar-week-day-bottom-middle"],
                              [NSImage imageNamed:@"calendar-week-day-bottom-right"],
                              NSCompositeCopy,
                              1.0,
                              YES);

    // Inset layer bounds, since images have 1px stroke.
    [WhiteToTransparentGradient drawInRect:NSInsetRect(NSRectFromCGRect(self.bounds),
                                                       1.0,
                                                       1.0)
                                     angle:90];
#endif
    if ([self.title length] > 0 && NSIntersectsRect(NSRectFromCGRect(self.titleFrame), dirtyRect))
    {
        NSDictionary *attributes = self.isTitleHighlighted ? [NSDictionary WL_highlightedTitleAttributes] : [NSDictionary WL_titleAttributes];
        // Vertically center the title.
        NSSize preferredTitleSize = [self.title boundingRectWithSize:NSSizeFromCGSize(self.titleFrame.size)
                                                             options:_WLTitleDrawingOptions
                                                          attributes:attributes].size;
        NSRect centeredFrame = NSRectFromCGRect(self.titleFrame);
        CGFloat yOffset = ceil(fdim(self.titleFrame.size.height / 2.0, preferredTitleSize.height / 2.0));
        centeredFrame.origin.y += yOffset;
        centeredFrame.size.height = fdim(centeredFrame.size.height, yOffset);
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] setFill];
        NSRectFill(centeredFrame);
#endif
        [self.title drawWithRect:centeredFrame
                         options:_WLTitleDrawingOptions
                      attributes:attributes];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end


@implementation NSDictionary (WLCalendarDayEventsBackgroundLayer)

+ (NSDictionary *)WL_titleAttributes
{
    static dispatch_once_t onceToken;
    static NSDictionary *titleAttributes = nil;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        [p setAlignment:NSCenterTextAlignment];
        [p setLineBreakMode:NSLineBreakByWordWrapping];
        NSShadow *s = [[NSShadow alloc] init];
        [s setShadowBlurRadius:0.0];
        [s setShadowColor:[NSColor WL_columnTitleShadowColor]];
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            [s setShadowOffset:NSMakeSize(0.0, -1.0)];
        else
            [s setShadowOffset:NSMakeSize(0.0, 1.0)];
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           (id)[NSFont WL_columnTitleFont],  NSFontAttributeName,
                           p,                                NSParagraphStyleAttributeName,
                           [NSColor whiteColor],             NSForegroundColorAttributeName,
                           s,                                NSShadowAttributeName,
                           nil];
        [s release];
        [p release];
    });
    return titleAttributes;
}

+ (NSDictionary *)WL_highlightedTitleAttributes
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *highlightedTitleAttributes = nil;
    dispatch_once(&onceToken, ^{
        NSDictionary *titleAttributes = [self WL_titleAttributes];
        highlightedTitleAttributes = [titleAttributes mutableCopy];
        [highlightedTitleAttributes setObject:(id)[NSFont WL_columnBoldTitleFont] forKey:NSFontAttributeName];
    });
    return highlightedTitleAttributes;
}

@end
