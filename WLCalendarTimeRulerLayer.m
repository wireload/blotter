//
//  WLCalendarTimeRulerLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTimeRulerLayer.h"
#import "NSColor+CGColor.h"
#import "CoreAnimation+WLCalendar.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


@implementation WLCalendarTimeRulerLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedTimeLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithLayer:(id)aLayer
{
    self = [super initWithLayer:aLayer];
    if (self != nil)
    {
        self.timeRuler = [aLayer timeRuler];
    }
    return self;
}

- (void)dealloc
{
    [_sortedTimeLayers release];
    [super dealloc];
}


#pragma mark Properties
@synthesize timeRuler;
@synthesize shouldHideHalfVisibleHourLabels;


#pragma mark Methods

- (CGFloat)hourLabelYPadding
{
    if ([_sortedTimeLayers count] > 0)
        return [[_sortedTimeLayers objectAtIndex:0] preferredFrameSize].height / 2;
    else
        return 0.0f;
}

- (void)setHours:(NSArray *)hours
{
    [_sortedTimeLayers removeAllObjects];
    self.sublayers = nil;
    for (NSString *hour in hours)
    {
        WLCalendarTimeRulerLabelLayer *timeLayer = [self _setupTimeLayerWithString:hour];
        [self addSublayer:timeLayer];
        [_sortedTimeLayers addObject:timeLayer];
    }
    _shouldUpdatePreferredFrameWidthCache = YES;
}

- (CGPoint)pointForHour:(CGFloat)aHour
{
    return CGPointMake(0.0f, floorf([self hourLabelYPadding] + aHour * timeRuler.heightOfHour));
}

- (CGFloat)preferredFrameWidth
{
    if ([_sortedTimeLayers count] == 0)
        return 0.0f;

    if (_shouldUpdatePreferredFrameWidthCache)
    {
        _cachedPreferredFrameWidth = 0.0f;
        for (CALayer *l in _sortedTimeLayers)
            _cachedPreferredFrameWidth = fmaxf(_cachedPreferredFrameWidth, [l preferredFrameSize].width);
        _shouldUpdatePreferredFrameWidthCache = NO;
    }
    return _cachedPreferredFrameWidth;
}


#pragma mark Private

- (WLCalendarTimeRulerLabelLayer *)_setupTimeLayerWithString:(NSString *)aTime
{
    WLCalendarTimeRulerLabelLayer *l = [WLCalendarTimeRulerLabelLayer layer];
    CTTextAlignment a = kCTRightTextAlignment;
    CTParagraphStyleSetting alignmentSetting = {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = &a};
    CTParagraphStyleRef p = CTParagraphStyleCreate(&alignmentSetting, 1);
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                (id)[NSFont WL_timeRulerLabelFont],                 (id)kCTFontAttributeName,
                                (id)[[NSColor WL_timeRulerLabelColor] WL_CGColor],  (id)kCTForegroundColorAttributeName,
                                (id)p,                                              (id)kCTParagraphStyleAttributeName,
                                nil];
    CFRelease(p);
    l.string = [[[NSAttributedString alloc] initWithString:aTime attributes:attributes] autorelease];
    l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    return l;
}


#pragma mark CALayer

- (CGSize)preferredFrameSize
{
    if ([_sortedTimeLayers count] == 0)
        return CGSizeZero;

    CGFloat h = floorf(timeRuler.heightOfHour * [_sortedTimeLayers count] + [self hourLabelYPadding]);
    return CGSizeMake([self preferredFrameWidth], h);
}

- (void)layoutSublayers
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGFloat heightOfHour = timeRuler.heightOfHour;
    CGFloat hourPosition = [self hourLabelYPadding];
    for (WLCalendarTimeRulerLabelLayer *hourLabel in _sortedTimeLayers)
    {
        CGSize size = [hourLabel preferredFrameSize];
        hourLabel.frame = CGRectIntegral(CGRectMake(0.0f, hourPosition - size.height / 2.0, self.bounds.size.width, size.height));
        if (shouldHideHalfVisibleHourLabels)
        {
            if (CGRectGetMaxY(self.visibleRect) < CGRectGetMaxY(hourLabel.frame))
                hourLabel.hidden = YES;
            else
                hourLabel.hidden = NO;
        }
        hourPosition += heightOfHour;
    }
}

@end
