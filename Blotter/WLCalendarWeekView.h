//
//  WLCalendarWeekView.h
//  Blotter
//
//  Created by Ilya Kulakov on 10.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CalendarStore/CalendarStore.h>
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarTimeRuler.h"
#import "WLCalendarTimeRulerLayer.h"
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarTimeIndicatorLayer.h"
#import "WLCalendarDayEventsBackgroundLayer.h"
#import "WLHourRange.h"


@protocol WLCalendarWeekViewDataSource;


typedef enum
{
    WLRightToLeftDirection,
    WLLeftToRightDirection
} WLDayAppearanceDirection;


@interface WLCalendarWeekView : WLLayerHostedView <WLCalendarTimeRuler/*, CALayerManager, CALayerDelegate*/> {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat heightOfAllDayPartOfColumn;
    BOOL showsTimeIndicator;
    BOOL fitsDayEvents;
    BOOL showsAllDayEvents;
    WLHourRange alwaysVisibleHourRange;
    BOOL needsUpdateHoursLengthAndPositions;

    CGFloat _hour;
    NSUInteger _numberOfActiveShowDaysTransactions;

    // MUST be >= 24
    // Sizes MUST be equal
    CGFloat _lengthOfHours[32]; // extra hours for safety
    CGFloat _locationOfHours[32]; // extra hours for safety
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

/*!
 @discussion Default value is YES.
 */
@property (nonatomic) BOOL showsAllDayEvents;

/*!
 @discussion    Default value is 114.
 */
@property (nonatomic) CGFloat heightOfAllDayPartOfColumn;

/*!
 @discussion    Default value is YES.
 */
@property (nonatomic) BOOL showsTimeIndicator;

/*!
 @abstract      Determines whether view tries to fit all day events.
 @discussion    Default value is NO.
 When set to NO, the view focuses on current hour (tries to center it) and keeps text of events visible.
 */
@property (nonatomic) BOOL fitsDayEvents;

/*!
 @abstract      Returns range of always visible hours when shouldFitAllDayEvents is set to YES.
 @discussion    Default value is [9.0, 17.0].
 Affects layout.
 */
@property (nonatomic) WLHourRange alwaysVisibleHourRange;

- (void)reloadDataAnimated:(BOOL)isAnimated;

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateHighlightsTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;;

- (void)showDays:(NSUInteger)aNumberOfDaysToShow
        hideDays:(NSUInteger)aNumberOfDaysToHide
       direction:(WLDayAppearanceDirection)aDirection
        animated:(BOOL)isAnimated;

- (NSUInteger)numberOfColumns;

/*!
 @abstract      Returns hour range that represents all events.
 @discussion    Hour aligned. That is, if the "real" hour range is [9h 32m, 22h 13m], it will return [9h, 23h].
 @see           visibleHourRange
 */
- (WLHourRange)hourRangeOfEvents;

/*!
 @abstract      Determines visible hour range based on value of alwaysVisibleHourRange and range day events.
 @see           alwaysVisibleHourRange
 */
- (WLHourRange)visibleHourRange;

- (BOOL)needsUpdateHoursLengthAndLocation;

- (void)setNeedsUpdateHoursLengthAndLocation;

- (void)updateHoursLengthAndLocationIfNeeded;


- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateHighlightsTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)_timeRulerMarkers;

@end

#pragma mark -

@interface WLCalendarWeekView (Layers)

#pragma mark Time Ruler Layers

- (CALayer *)setupTimeRulerRootLayer;

- (WLBlockLayer *)setupTimeRulerBackgroundLayer;

- (CAScrollLayer *)setupTimeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer;

#pragma mark Event Layers

- (CALayer *)setupEventsRootLayer;

- (CALayer *)setupColumnRootLayer;

- (WLBlockLayer *)setupAllDayBackgroundLayer;

- (WLCalendarDayEventsBackgroundLayer *)setupDayBackgroundLayer;

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer;

- (CAScrollLayer *)setupDayScrollLayer;

- (WLCalendarDayEventsLayer *)setupDayLayer;

#pragma mark Time Indicator Layers

- (CALayer *)setupTimeIndicatorRootLayer;

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer;

#pragma mark Access Layers

- (CALayer *)timeRulerRootLayer;

- (WLBlockLayer *)timeRulerBackgroundLayer;

- (CAScrollLayer *)timeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)timeRulerLayer;

- (CALayer *)eventsRootLayer;

- (NSMutableArray *)columnRootLayers;

- (void)setColumnRootLayers:(NSMutableArray *)newColumnRootLayers;

- (NSArray *)dayBackgroundLayers;

- (NSArray *)dayScrollLayers;

- (NSArray *)dayLayers;

- (NSArray *)allDayBackgroundLayers;

- (NSArray *)allDayLayers;

- (CALayer *)timeIndicatorRootLayer;

- (WLCalendarTimeIndicatorLayer *)timeIndicatorLayer;

@end

#pragma mark -

@interface WLCalendarWeekView (Layout)

#pragma mark Root Layer

- (void)layoutSublayersOfRootLayer:(CALayer *)aRootLayer;

#pragma mark Time Ruler Layers

- (void)layoutSublayersOfTimeRulerRootLayer:(CALayer *)aTimeRulerRootLayer;

- (void)layoutSublayersOfTimeRulerBackgroundLayer:(WLBlockLayer *)aTimeRulerBackgroundLayer;

- (void)layoutSublayersOfTimeRulerScrollLayer:(CAScrollLayer *)aTimeRulerScrollLayer;

- (void)invalidateLayoutOfTimeRulerRootLayer:(CALayer *)aTimeRulerRootLayer;

#pragma mark Event Layers

- (void)layoutSublayersOfEventsRootLayer:(CALayer *)anEventsRootLayer;

- (void)layoutSublayersOfColumnRootLayer:(CALayer *)aColumnRootLayer;

- (void)layoutSublayersOfAllDayBackgroundLayer:(WLBlockLayer *)anAllDayBackgroundLayer;

- (void)layoutSublayersOfDayBackgroundLayer:(WLCalendarDayEventsBackgroundLayer *)aDayBackgroundLayer;

- (void)layoutSublayersOfDayScrollLayer:(CAScrollLayer *)aDayScrollLayer;

#pragma mark Time Indicator Layers

- (void)layoutSublayersOfTimeIndicatorRootLayer:(CALayer *)aTimeIndicatorRootLayer;

#pragma mark Layout Calculations

- (CGFloat)heightAndMarginOfAllDayEventsPartOfColumn;

/*!
 @abstract  Returns frames for a given number of columns within current events root layer.
 @see       eventsRootLayer
 */
- (NSArray *)framesForNumberOfColumns:(NSUInteger)aNumberOfColumns;

/*!
 @discussion    Frame of column title is general for all columns.
 */
- (NSRect)columnTitleFrame;

- (CGPoint)scrollPoint;

- (CGPoint)scrollPointToFocusOnDayEvents;

- (CGPoint)scrollPointToFocusOnCurrentHour;

- (BOOL)isAllDayPartOfColumnVisible;

- (CGFloat)visibleHeightOfTimeRuler;

- (CGFloat)positionForTimeIndicator;

@end

#pragma mark -

enum
{
    WLCalendarWeekViewTitleDataUnit = 1 << 0,
    WLCalendarWeekViewEventsDataUnit = 1 << 1,
    WLCalendarWeekViewColorDataUnit = 1 << 2,
    WLCalendarWeekViewHighlightsTitleDataUnit = 1 << 3
};


@protocol WLCalendarWeekViewDataSource

/*!
    @result     MUST lie within [0.0, 32.0).
 */
- (WLHourRange)hourRangeOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView allDayEventsForColumnAtIndex:(NSUInteger)anIndex;

- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate;

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView stringForHour:(NSUInteger)aHour;

@optional

/*!
 @discussion    You MUST pair this call with -weekViewDidAskForData:.
 */
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex;

- (BOOL)weekView:(WLCalendarWeekView *)aWeekView highlightsTitleForColumnAtIndex:(NSUInteger)anIndex;

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex;

@end
