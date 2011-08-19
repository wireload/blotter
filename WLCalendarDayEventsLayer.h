//
//  WLCalendarWeekdayEventsLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarTimeRuler.h"
#import "WLDateRange.h"


@class WLCalendarEventLayer;


@interface WLCalendarDayEventsLayer : CALayer {
    NSMutableArray *_sortedByStartDateEventLayers;
    NSMutableArray *_sortedByUIDEventLayers;
    NSUInteger _cachedMaximumNumberOfColumns;
    NSTreeNode *_eventsLayoutTreeRootNode;
    BOOL _eventsChanged;

    id<WLCalendarTimeRuler> timeRuler;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property (nonatomic, copy) NSSet *events;

- (NSUInteger)maximumNumberOfColumns;

- (WLDateRange *)eventsDateRange;


- (WLCalendarEventLayer *)_setupEventLayer;

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent;

- (NSUInteger)_indexOfEventLayerWithStartDate:(NSDate *)aStartDate;

- (NSUInteger)_indexOfEventLayerWithUID:(NSString *)anUID isFound:(BOOL *)outIsFound;

- (void)_buildEventsLayoutTree;

@end
