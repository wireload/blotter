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

    WLHourRange hourRangeOfEvents;
    BOOL _needsUpdateHourRangeOfEvents;

    struct
    {
        CGFloat cachedLayerHeight;
        CGFloat cachedStartHour;
        WLHourRange cachedOutHourRange;
        CGFloat cachedOutLayerHeight;
    } _toFitAllEventsCache;
    BOOL _needsUpdateToFitAllEventsCache;

    NSMutableArray *_sortedByStartDateEventLayers;
    NSTreeNode *_eventsLayoutTreeRootNode;
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
 @abstract      Returns maximum number of horizontal adjacent events.
 @discussion    Minimum value is 1.
 */
- (NSUInteger)maximumNumberOfColumns;

/*!
 @abstract  Returns actual hour range of events.
 @result    Returns WLHourRangeZero if no events are specified.
 */
- (WLHourRange)hourRangeOfEvents;

- (CGFloat)preferredFrameWidth;

/*!
 @abstract  Returns extent below last hour depending on timeRuler settings.
 @see       timeRuler
 */
- (CGFloat)extent;

/*!
 @abstract      Calculates preferred layout settings that you CAN use to calculate height of hour.
 @result        If returns NO, you MUST NOT rely on this layer while calculating height of hour.
 @see           hourRangeOfEvents
 */
- (BOOL)toFitAllEventsWithinLayerHeight:(CGFloat)aLayerHeight
                       startingWithHour:(CGFloat)aStartHour
                              hourRange:(out WLHourRange *)outHourRange
        shouldBePlacedWithinLayerHeight:(out CGFloat *)outLayerHeight;


- (WLCalendarEventLayer *)_setupEventLayer;

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent;

- (NSUInteger)_indexForInsertionOfEventLayerWithEvent:(id)anEvent;

- (void)_buildEventsLayoutTreeIfNeeded;

- (void)_buildEventsLayoutTree;

- (WLHourRange)_hourRangeOfEventLayer:(WLCalendarEventLayer *)aLayer;

- (CGRect)_yAndHeightOfEventLayer:(WLCalendarEventLayer *)aLayer;

@end
