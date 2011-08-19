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


@implementation WLCalendarTimeRulerLayer
@synthesize timeRuler;

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
        timeRuler = [aLayer timeRuler];
    }
    return self;
}

- (void)dealloc
{
    [_sortedTimeLayers release];
    [super dealloc];
}

- (CGFloat)firstHourYPadding
{
    if ([_sortedTimeLayers count] > 0)
        return [[_sortedTimeLayers objectAtIndex:0] preferredFrameSize].height / 2;
    else
        return 0.0f;
}

- (void)setHours:(NSArray *)hours
{
    [CATransaction begin];
    [_sortedTimeLayers removeAllObjects];
    self.sublayers = nil;
    for (NSString *hour in hours)
    {
        CATextLayer *timeLayer = [self _setupTimeLayerWithString:hour];
        [self addSublayer:timeLayer];
        [_sortedTimeLayers addObject:timeLayer];
    }
    [CATransaction commit];
    _shouldUpdatePreferredFrameWidthCache = YES;
}

- (CGPoint)pointForHour:(CGFloat)aHour
{
    return CGPointMake(0.0f, [self firstHourYPadding] + aHour * timeRuler.heightOfHour);
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

- (CATextLayer *)_setupTimeLayerWithString:(NSString *)aTime
{
    CATextLayer *l = [CATextLayer layer];
    [CATransaction WL_performWithDisabledActions:^{
        l.alignmentMode = kCAAlignmentRight;
        l.fontSize = 14.0f;
        l.string = aTime;
        l.wrapped = NO;
        l.truncationMode = kCATruncationNone;
//        l.shadowOpacity = 1.0f;
//        l.shadowOffset = CGSizeMake(0.0f, 1.0f);
//        l.shadowRadius = 1.0f;
#ifdef DEBUG_LAYERS
        l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    }];
    return l;
}


#pragma mark CALayer

- (CGSize)preferredFrameSize
{
    if ([_sortedTimeLayers count] == 0)
        return CGSizeZero;

    CGFloat h = timeRuler.heightOfHour * [_sortedTimeLayers count] + [self firstHourYPadding];
    return CGSizeMake([self preferredFrameWidth], h);
}

- (void)layoutSublayers
{
#ifdef DEBUG_PERFORMANCE
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");

    CGFloat heightOfHour = timeRuler.heightOfHour;
    CGFloat yOffset = [self firstHourYPadding];
    for (CATextLayer *timeLayer in _sortedTimeLayers)
    {
        CGSize size = [timeLayer preferredFrameSize];
        timeLayer.frame = CGRectMake(0.0f, floorf(yOffset - size.height / 2), self.bounds.size.width, size.height);
        yOffset += heightOfHour;
    }
}

@end
