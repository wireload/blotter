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
#import "WLHourRange.h"


@class WLCalendarEventLayer;


@interface WLCalendarDayEventsLayer : CALayer {
    BOOL keepTextOfEventsVisible;
    NSMutableArray *_sortedByStartDateEventLayers;
    NSMutableArray *_sortedByUIDEventLayers;
    NSUInteger _maximumNumberOfColumns;
    NSTreeNode *_eventsLayoutTreeRootNode;
    BOOL _eventsChanged;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property (nonatomic, copy) NSSet *events;

/*!
 @abstract Indicates whether text of event is visible if visible rect of event is changed (e.g. because of scrolling).
 */
@property (nonatomic) BOOL keepTextOfEventsVisible;

/*!
 @abstract Height of house used for layout.
 */
@property CGFloat heightOfHour;

/*!
 @abstract      Returns maximum number of horizontal adjacent events.
 @discussion    Minimum value is 1.
 */
- (NSUInteger)maximumNumberOfColumns;

/*!
 @abstract  Returns actual hour range of events.
 @see       visibleHourRangeOfEventsForHeightOfHour
 */
- (WLHourRange)hourRangeOfEvents;

/*!
 @abstract      Returns visible hour range of events taking care of minimum visible heights of events.
 @discussion    E.g. event's length is 5 minutes and passed height of hour is 10 points. Therefore calculated height of event is
 0.16 (assuming 60 minutes/hour) but it may be less than minimumVisibleHeight so it will be extended.
 @see           hourRangeOfEvents
 */
- (WLHourRange)visibleHourRangeOfEventsForHeightOfHour:(CGFloat)aHeightOfHour;


- (WLCalendarEventLayer *)_setupEventLayer;

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent;

- (NSUInteger)_indexForInsertionOfEventLayerWithStartDate:(NSDate *)aStartDate;

- (NSUInteger)_indexOfEventLayerWithUID:(NSString *)anUID isFound:(out BOOL *)outIsFound;

- (void)_buildEventsLayoutTree;

- (CGFloat)_minYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour;

- (CGFloat)_maxYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour minY:(CGFloat)aMinY;

@end
