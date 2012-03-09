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
#import "WLCalendarEventLayer.h"
#import "WLHourRange.h"


@interface WLCalendarDayEventsLayer : CALayer {
    BOOL keepsTextOfEventsVisible;
    WLHourRange hourRangeOfEvents;

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

@property (assign) NSObject<WLCalendarTimeRuler> *timeRuler;

@property (nonatomic, copy) NSSet *events;

@property (nonatomic) BOOL keepsTextOfEventsVisible;

/*!
 @abstract  Returns actual hour range of events.
 @result    Hour range of events or WLHourRangeZero if no events are specified.
 */
@property (readonly) WLHourRange hourRangeOfEvents;

/*!
 @abstract      Returns maximum number of horizontal adjacent events.
 @discussion    Minimum value is 1.
 */
- (NSUInteger)maximumNumberOfColumns;

- (CGFloat)preferredFrameWidth;

/*!
 @abstract      Returns extent below end of hourRangeOfEvents.
 @discussion    If calculated height of event is less than suggested minimum visible height, it will be extended.
 The number of points which exceed its calculated bounds is called extent.
 Users of WLCalendarDayEventsLayer are interested only in largest extent below end of hourRangeOfEvents.
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


- (NSUInteger)_indexForInsertionOfEventLayerWithEvent:(id)anEvent;

- (void)_buildEventsLayoutTreeIfNeeded;

- (void)_buildEventsLayoutTree;

@end


typedef struct _WLSegment
{
    CGFloat location;
    CGFloat length;
} WLSegment;


NS_INLINE CGFloat WLSegmentGetMinLocation(WLSegment aSegment)
{
    return aSegment.location;
}


NS_INLINE CGFloat WLSegmentGetMaxLocation(WLSegment aSegment)
{
    return aSegment.location + aSegment.length;
}


@interface WLCalendarEventLayer (WLCalendarDayEventsLayer)

@property (nonatomic, retain) id dayEvent;

@property (nonatomic) NSUInteger numberOfColumnsToSkip;

@property (nonatomic) WLHourRange hourRange;

+ (WLCalendarEventLayer *)makeDayEventLayer;

- (WLSegment)segmentOnTimeRuler:(NSObject<WLCalendarTimeRuler> *)aTimeRuler;

@end


@interface NSDictionary (WLCalendarDayEventsLayer)

+ (NSDictionary *)WL_dayEventTitleAttributes;

+ (NSDictionary *)WL_dayEventLocationAttributes;

@end
