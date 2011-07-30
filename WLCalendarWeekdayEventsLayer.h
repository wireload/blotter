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
    NSUInteger _cachedMaximumNumberOfColumns;
    NSTreeNode *_eventsLayoutTreeRootNode;
    BOOL _eventsChanged;

    id<WLCalendarTimeRuler> timeRuler;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property (nonatomic, copy) NSSet *events;

- (NSUInteger)maximumNumberOfColumns;


- (WLCalendarEventLayer *)_setupEventLayerWithEvent:(id)anEvent;

- (NSUInteger)_indexOfEventLayerForStartDate:(id)aStartDate;

- (void)_buildEventsLayoutTree;

@end
