//
//  WLCalendarTimeRulerLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 19.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#include <tgmath.h>
#import "WLCalendarTimeRulerLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


@implementation WLCalendarTimeRulerLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _sortedMarkerLayers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_sortedMarkerLayers release];
    [super dealloc];
}


#pragma mark Properties
@dynamic timeRuler;
@dynamic onlyCompletelyVisibleMarkersShown;
@dynamic markers;

- (NSArray *)markers
{
    return [_sortedMarkerLayers valueForKeyPath:@"marker.string"];
}

- (void)setMarkers:(NSArray *)aHours
{
    if ([aHours count] > [_sortedMarkerLayers count])
    {
        for (NSUInteger i = 0, size = [aHours count] - [_sortedMarkerLayers count]; i < size; ++i)
        {
            WLCalendarTimeRulerMarkerLayer *markerLayer = [self setupMarkerLayer];
            [_sortedMarkerLayers addObject:markerLayer];
            [self addSublayer:markerLayer];
        }
    }
    else if ([aHours count] < [_sortedMarkerLayers count])
    {
        NSRange rangeOfmarkerLayersToRemove = NSMakeRange(0, [_sortedMarkerLayers count] - [aHours count]);
        NSArray *markerLayersToRemove = [_sortedMarkerLayers subarrayWithRange:rangeOfmarkerLayersToRemove];
        [markerLayersToRemove makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        [_sortedMarkerLayers removeObjectsInRange:rangeOfmarkerLayersToRemove];
    }
    
    NSParameterAssert([aHours count] == [_sortedMarkerLayers count]);
    
    [aHours enumerateObjectsUsingBlock:^(NSString *marker, NSUInteger idx, BOOL *stop) {
        WLCalendarTimeRulerMarkerLayer *l = [_sortedMarkerLayers objectAtIndex:idx];
        if (![[l.marker string] isEqualToString:marker])
        {
            static dispatch_once_t onceToken;
            static NSDictionary *attributes = nil;
            dispatch_once(&onceToken, ^{
                CTTextAlignment a = kCTRightTextAlignment;
                CTParagraphStyleSetting alignmentSetting = {.spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(CTTextAlignment), .value = &a};
                CTParagraphStyleRef p = CTParagraphStyleCreate(&alignmentSetting, 1);
                attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                              (id)[NSFont WL_timeRulerMarkerFont],                (id)kCTFontAttributeName,
                              (id)[[NSColor WL_timeRulerMarkerColor] WL_CGColor], (id)kCTForegroundColorAttributeName,
                              (id)p,                                              (id)kCTParagraphStyleAttributeName,
                              nil];
                CFRelease(p);
            });
            l.marker = [[[NSAttributedString alloc] initWithString:marker attributes:attributes] autorelease];
            _shouldUpdatePreferredFrameWidthCache = YES;
        }
    }];
}


#pragma mark Methods

- (CGFloat)maximumHeightOfMarker
{
    if ([_sortedMarkerLayers count] > 0)
        return [[_sortedMarkerLayers objectAtIndex:0] preferredFrameSize].height;
    else
        return 0.0;
}

- (CGFloat)preferredFrameWidth
{
    if ([_sortedMarkerLayers count] == 0)
        return 0.0;

    if (_shouldUpdatePreferredFrameWidthCache)
    {
        _cachedPreferredFrameWidth = 0.0;
        for (CALayer *l in _sortedMarkerLayers)
            _cachedPreferredFrameWidth = fmax(_cachedPreferredFrameWidth, [l preferredFrameSize].width);
        _shouldUpdatePreferredFrameWidthCache = NO;
    }
    return _cachedPreferredFrameWidth;
}


#pragma mark CALayer

- (CGSize)preferredFrameSize
{
    if ([_sortedMarkerLayers count] == 0)
        return CGSizeZero;

    CGFloat h = [self.timeRuler originOffset] + [self.timeRuler heightForHourRange:[self.timeRuler hourRange]];
    return CGSizeMake([self preferredFrameWidth], h);
}

- (void)layoutSublayers
{
    NSAssert(self.layoutManager == nil, @"You cannot use custom layout managers with this class");
    
    WLHourRange r = [self.timeRuler hourRange];
    NSUInteger numberOfMarkers = [_sortedMarkerLayers count];
    WLEnumerateHourRange(r, NSHourCalendarUnit, ^(NSCalendarUnit aUnit, NSUInteger anIndex, CGFloat aMatchedValue, BOOL *aShouldStop)
    {
        if (anIndex < numberOfMarkers)
        {
            WLCalendarTimeRulerMarkerLayer *hourMarker = [_sortedMarkerLayers objectAtIndex:anIndex];
            CGSize size = [hourMarker preferredFrameSize];
            CGFloat hourPosition = [self.timeRuler positionForHour:aMatchedValue];
            hourMarker.frame = CGRectIntegral(CGRectMake(0.0, hourPosition - size.height / 2.0, self.bounds.size.width, size.height));
            if (self.onlyCompletelyVisibleMarkersShown)
            {
                if (CGRectGetMaxY(self.visibleRect) < CGRectGetMaxY(hourMarker.frame))
                    hourMarker.hidden = YES;
                else
                    hourMarker.hidden = NO;
            }
        }
        else
            *aShouldStop = YES;
    });
}

@end


#pragma mark -

@implementation WLCalendarTimeRulerLayer (Layers)

- (WLCalendarTimeRulerMarkerLayer *)setupMarkerLayer
{
    WLCalendarTimeRulerMarkerLayer *l = [WLCalendarTimeRulerMarkerLayer layer];
    l.needsDisplayOnBoundsChange = YES;
#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    return l;
}

@end

