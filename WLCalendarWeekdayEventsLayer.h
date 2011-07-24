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


@class WLCalendarEventLayer;


@interface WLCalendarWeekdayEventsLayer : CALayer {
    NSMutableArray *_sortedEventLayers;
    NSMutableSet *_uids;
    id<WLCalendarTimeRuler> timeRuler;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

- (void)addEvent:(id)anEvent;

- (void)updateEvent:(id)anEvent;

- (void)removeEvent:(id)anEvent;

- (void)setEvents:(NSSet *)events;


- (WLCalendarEventLayer *)_setupEventLayerWithEvent:(id)anEvent;

- (NSUInteger)_indexOfEventLayerForStartDate:(id)aStartDate;

@end
