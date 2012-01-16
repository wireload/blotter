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
    BOOL keepsTextOfEventsVisible;
    NSMutableArray *_sortedByStartDateEventLayers;
    NSMutableArray *_sortedByUIDEventLayers;
    NSUInteger _maximumNumberOfColumns;
    NSTreeNode *_eventsLayoutTreeRootNode;
    BOOL _areEventsChanged;
    BOOL _isHeightChanged;
}

/*!
 @discussion    Affects layout.
 */
@property (assign) id<WLCalendarTimeRuler> timeRuler;

/*!
 @discussion    Affects layout and display.
 */
@property (nonatomic, copy) NSSet *events;

/*!
 @abstract      Indicates whether text of event is visible if visible rect of event is changed (e.g. because of scrolling).
 @discussion    Affects display.
 */
@property (nonatomic) BOOL keepsTextOfEventsVisible;

/*!
 @abstract Height of house used for layout.
 @discussion    Affects layout.
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
 Returned range always either contains -hourRangeOfEvents or equal to it.
 @see           hourRangeOfEvents
 */
- (WLHourRange)visibleHourRangeOfEventsForHeightOfHour:(CGFloat)aHeightOfHour;


- (WLCalendarEventLayer *)_setupEventLayer;

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent;

- (NSUInteger)_indexForInsertionOfEventLayerWithStartDate:(NSDate *)aStartDate;

- (NSUInteger)_indexForInsertionOfEventLayerWithUID:(NSString *)anUID isFound:(out BOOL *)outIsFound;

- (void)_buildEventsLayoutTreeIfNeeded;

- (void)_buildEventsLayoutTree;

/*!
 @abstract  Returns start hour of a given layer.
 */
- (CGFloat)_startHourOfEventLayer:(WLCalendarEventLayer *)aLayer;

/*!
 @abstract  Returns end hour of a given layer.
 */
- (CGFloat)_endHourOfEventLayer:(WLCalendarEventLayer *)aLayer;

/*!
 @abstract  Returns minY for event layer for layout.
 */
- (CGFloat)_minYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour;

/*!
 @abstract  Returns maxY for event layer for layout.
 */
- (CGFloat)_maxYOfEventLayer:(WLCalendarEventLayer *)aLayer forHeightOfHour:(CGFloat)aHeightOfHour minY:(CGFloat)aMinY;

@end
