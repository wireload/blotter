//
//  WLCalendarAllDayEventsLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarEventLayer.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString* const _WLEventKey = @"WLCalendarAllDayEventsLayer_event";


static const CGFloat _WLTopMargin = 10.0;


static const CGFloat _WLXPadding = 2.0;


@implementation WLCalendarAllDayEventsLayer
{
    NSMutableArray *_eventLayers;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        _eventLayers = [[NSMutableArray alloc] init];
    }

    return self;
}


#pragma mark Properties
@dynamic events;

- (NSArray *)events
{
    return [_eventLayers valueForKey:@"allDayEvent"];
}

- (void)setEvents:(NSArray *)newEvents
{
    NSMutableArray *unusedSublayers = [_eventLayers mutableCopy];
    [_eventLayers removeAllObjects];

    for (NSObject <WLCalEvent> *event in newEvents)
    {
        NSUInteger indexOfUsedLayer = [unusedSublayers indexOfObjectPassingTest:^BOOL(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            return [event isLikeEvent:l.allDayEvent];
        }];

        WLCalendarEventLayer *usedLayer = nil;

        if (indexOfUsedLayer != NSNotFound)
        {
            // Layer for the event already exist. Update it.
            usedLayer = unusedSublayers[indexOfUsedLayer];
            usedLayer.allDayEvent = event;
            [unusedSublayers removeObjectAtIndex:indexOfUsedLayer];
        }
        else
        {
            // Create new layer for the event.
            usedLayer = [self makeAllDayEventLayer];
            usedLayer.allDayEvent = event;
            [self addSublayer:usedLayer];
        }

        [_eventLayers addObject:usedLayer];
    }

    [unusedSublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
}


#pragma mark Methods

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth
{
    CGFloat preferredHeight = 0.0;

    for (WLCalendarEventLayer *layer in _eventLayers)
        preferredHeight += _WLTopMargin + [layer preferredHeightWithWidth:aWidth];

    return preferredHeight;
}

- (WLCalendarEventLayer *)makeAllDayEventLayer
{
    WLCalendarEventLayer *l = [WLCalendarEventLayer layer];
    l.needsDisplayOnBoundsChange = YES;
    l.delegate = self;
#ifndef DEBUG_LAYERS
    l.contentsBackgroundOpacity = 0.45;
#endif

    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
        l.contentsScale = self.contentsScale;

    return l;
}


#pragma mark CALayerDelegate

- (BOOL)layer:(CALayer *)aLayer shouldInheritContentsScale:(CGFloat)aNewScale fromWindow:(NSWindow *)aWindow
{
    return [(NSView *)self.delegate layer:self shouldInheritContentsScale:aNewScale fromWindow:aWindow];
}


#pragma mark CALayer

- (void)layoutSublayers
{
    if ([_eventLayers count] == 0 || self.bounds.size.width == 0.0 || self.bounds.size.height == 0.0)
        return;

    // Origin is top left
    NSMutableArray *preferredHeightOfLayers = [NSMutableArray arrayWithCapacity:[_eventLayers count]];
    NSMutableArray *minimumHeightOfLayers = [NSMutableArray arrayWithCapacity:[_eventLayers count]];
    CGFloat totalPreferredHeight = CGRectGetMinY(self.bounds);
    CGFloat totalMinimumHeight = CGRectGetMinY(self.bounds);
    CGFloat totalVisibleHeight = CGRectGetHeight(self.bounds);
    CGFloat availableWidth = CGRectGetWidth(self.bounds) - _WLXPadding;

    for (WLCalendarEventLayer *l in _eventLayers)
    {
        CGFloat preferredHeight = [l preferredHeightWithWidth:availableWidth];
        totalPreferredHeight += _WLTopMargin + preferredHeight;
        [preferredHeightOfLayers addObject:@(preferredHeight)];

        CGFloat minimumHeight = [l minimumHumanVisibleHeightWithWidth:availableWidth];
        totalMinimumHeight += _WLTopMargin + minimumHeight;
        [minimumHeightOfLayers addObject:@(minimumHeight)];
    }

    CGFloat frameX = floor(CGRectGetMinX(self.bounds) + _WLXPadding / 2.0);

    if (totalVisibleHeight >= totalPreferredHeight)
    {
        __block CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
        [_eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            CGFloat preferredHeight = [preferredHeightOfLayers[idx] doubleValue];
            l.frame = CGRectMake(frameX,
                                 offset,
                                 availableWidth,
                                 preferredHeight);
            offset = CGRectGetMaxY(l.frame) + _WLTopMargin;
        }];
    }
    else if (totalVisibleHeight >= totalMinimumHeight/* && totalVisibleHeight < totalPreferredHeight */)
    {
        __block CGFloat availableHeight = totalVisibleHeight - totalMinimumHeight;
        __block CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
        [_eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            CGFloat preferredHeight = [preferredHeightOfLayers[idx] doubleValue];
            CGFloat minimumHeight = [minimumHeightOfLayers[idx] doubleValue];
            CGFloat height = minimumHeight;
            // If there is available space, it's wise to provide it layers that need it.
            CGFloat additionalHeight = fmin(fdim(preferredHeight, minimumHeight), availableHeight);
            height += additionalHeight;
            availableHeight = fdim(availableHeight, additionalHeight);
            l.frame = CGRectMake(frameX,
                                 offset,
                                 availableWidth,
                                 height);
            offset += _WLTopMargin + height;
        }];

    }
    else /* (totalVisibleHeight < totalMinimumHeight) */
    {
        __block CGFloat offset = CGRectGetMinY(self.bounds) + _WLTopMargin;
        __block BOOL crossedMinimumHeight = NO;
        [_eventLayers enumerateObjectsUsingBlock:^(WLCalendarEventLayer *l, NSUInteger idx, BOOL *stop)
        {
            CGFloat minimumHeight = [minimumHeightOfLayers[idx] doubleValue];

            if (!crossedMinimumHeight && (offset + minimumHeight) > totalVisibleHeight)
            {
                crossedMinimumHeight = YES;
                // If for a given height layer cannot show at least one line of event's title, there is no reason to show it at all.
                offset = CGRectGetMinY(self.bounds) + totalVisibleHeight + _WLTopMargin;
            }

            l.frame = CGRectIntegral(CGRectMake(frameX,
                                                offset,
                                                availableWidth,
                                                minimumHeight));
            offset += _WLTopMargin + minimumHeight;
        }];
    }
}

- (CGSize)preferredFrameSize
{
    CGSize preferredSize = CGSizeMake(0.0, 0.0);

    for (WLCalendarEventLayer *layer in _eventLayers)
    {
        CGSize layerSize = [layer preferredFrameSize];
        preferredSize.width = MAX(preferredSize.width + _WLXPadding, layerSize.width + _WLXPadding);
        preferredSize.height += _WLTopMargin + layerSize.height;
    }

    return preferredSize;
}

@end


@implementation WLCalendarEventLayer (WLCalendarAllDayEventsLayer)

#pragma mark Properties
@dynamic allDayEvent;

- (id)allDayEvent
{
    return [self valueForKey:_WLEventKey];
}

- (void)setAllDayEvent:(NSObject <WLCalEvent> *)newEvent
{
    [self setValue:newEvent forKey:_WLEventKey];

    self.name = newEvent.itemIdentifier;
    self.title = [NSAttributedString WL_eventTitleWithString:newEvent.title];
    self.location = [NSAttributedString WL_eventLocationWithString:newEvent.location];
#ifdef DEBUG_LAYERS
    self.backgroundColor = [calendarColor WL_CGColor];
#else
    self.contentsBackgroundColor = [newEvent.calendar.color WL_CGColor];
#endif
}

@end
