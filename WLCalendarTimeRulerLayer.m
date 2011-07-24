//
//  WLCalendarTimeRulerLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTimeRulerLayer.h"
#import "NSColor+CGColor.h"


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

- (CGSize)preferredFrameSize
{
    if ([_sortedTimeLayers count] == 0)
        return CGSizeMake(0.0f, 0.0f);

    CGSize preferredSize = CGSizeMake(0.0f, 0.0f);
    for (CALayer *layer in _sortedTimeLayers)
    {
        preferredSize.width = fmaxf(preferredSize.width, [layer preferredFrameSize].width);
    }
    preferredSize.height = timeRuler.heightOfHour * [_sortedTimeLayers count] + [[_sortedTimeLayers objectAtIndex:0] preferredFrameSize].height / 2;
    return preferredSize;
}

- (void)layoutSublayers
{
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
}

- (CGPoint)pointForHour:(CGFloat)aHour
{
    return CGPointMake(0.0f, [self firstHourYPadding] + aHour * timeRuler.heightOfHour);
}


#pragma mark Private

- (CATextLayer *)_setupTimeLayerWithString:(NSString *)aTime
{
    CATextLayer *timeLayer = [CATextLayer layer];
    timeLayer.alignmentMode = kCAAlignmentRight;
    timeLayer.fontSize = 14.0f;
    timeLayer.string = aTime;
    timeLayer.wrapped = NO;
    timeLayer.truncationMode = kCATruncationNone;
#ifdef DEBUG_LAYERS
    timeLayer.backgroundColor = [[NSColor blueColor] WL_CGColor];
#endif
    return timeLayer;
}

@end
