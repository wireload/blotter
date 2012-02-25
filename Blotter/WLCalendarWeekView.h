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
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarTimeRuler.h"
#import "WLCalendarTimeRulerLayer.h"
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarTimeIndicatorLayer.h"
#import "WLHourRange.h"


@protocol WLCalendarWeekViewDataSource;


typedef enum
{
    WLRightToLeftDirection,
    WLLeftToRightDirection
} WLDayAppearanceDirection;


@interface WLCalendarWeekView : NSView <WLCalendarTimeRuler/*, CALayerManager, CALayerDelegate*/> {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat heightOfAllDayPartOfColumn;
    BOOL showsTimeIndicator;
    BOOL fitsDayEvents;
    NSUInteger indexOfHighlightedColumn;
    BOOL showsAllDayEvents;
    BOOL showsDayColumnTitle;
    WLHourRange alwaysVisibleHourRange;
    NSRect columnTitleFrame;
    BOOL needsUpdateColumnTitleFrame;

    CGFloat _hour;
    NSUInteger _numberOfActiveShowDaysTransactions;
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

/*!
 @discussion    Default value is 114.0f.
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
 @discussion    Pass NSNotFound if you want no columns to be highlighted.
 Default value is NSNotFound
 */
@property (nonatomic) NSUInteger indexOfHighlightedColumn;

/*!
 @discussion Default value is YES.
 */
@property (nonatomic) BOOL showsAllDayEvents;

/*!
 @discussion Default value is YES.
 */
@property (nonatomic) BOOL showsDayColumnTitle;

/*!
 @abstract      Returns range of always visible hours when shouldFitAllDayEvents is set to YES.
 @discussion    Default value is [09:00, 17:00].
 Affects layout.
 */
@property (nonatomic) WLHourRange alwaysVisibleHourRange;

- (void)reloadDataAnimated:(BOOL)isAnimated;

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet animated:(BOOL)isAnimated;;

- (void)showDays:(NSUInteger)aNumberOfDaysToShow
        hideDays:(NSUInteger)aNumberOfDaysToHide
       direction:(WLDayAppearanceDirection)aDirection
        animated:(BOOL)isAnimated;

- (void)stopAnimations;

- (void)pauseAnimations;

- (void)resumeAnimations;

- (NSUInteger)numberOfColumns;

/*!
 @abstract      Returns hour range that represents all events.
 @discussion    Hour aligned. That is, if the "real" hour range is [9h 32m, 22h 13m], it will return [9h, 23h].
 @see           visibleHourRange
 */
- (WLHourRange)hourRangeOfEvents;

/*!
 @see           alwaysVisibleHourRange
 */
- (WLHourRange)visibleHourRange;


- (void)_updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

/*!
 @discussion Sends setNeedsLayout to:
    1. dayLayer
    2. allDayLayer
    3. dayScrollLayer
    4. timeRulerScrollLayer
    5. timeIndicatorRootLayer
 @see dayLayers, allDayLayers, dayScrollLayers, timeRulerScrollLayer, timeIndicatorRootLayer
 */
- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

/*!
 @discussion Sends setNeedsLayout to:
    1. timeRulerBackgroundLayer
    2. dayBackgroundLayers
    3. timeIndicatorRootLayer
 @see timeRulerBackgroundLayer, dayBackgroundLayers, timeIndicatorRootLayer
 */
- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex;

- (NSDictionary *)_titleAttributesForColumnDayBackgroundLayer:(WLBlockLayer *)aLayer;

- (NSArray *)_timeRulerMarkers;

/*!
 @abstract  Updates the highlight property of day background layers and marks them needs display if needed.
 */
- (void)_updateHighlightColumnTitle;

@end

#pragma mark -

@interface WLCalendarWeekView (Layers)

- (void)setupLayers;

#pragma mark Root Layer

- (CALayer *)setupRootLayer;

#pragma mark Time Ruler Layers

- (CALayer *)setupTimeRulerRootLayer;

- (WLBlockLayer *)setupTimeRulerBackgroundLayer;

- (CAScrollLayer *)setupTimeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer;

#pragma mark Event Layers

- (CALayer *)setupEventsRootLayer;

- (CALayer *)setupColumnRootLayer;

- (WLBlockLayer *)setupAllDayBackgroundLayer;

- (WLBlockLayer *)setupDayBackgroundLayer;

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

#pragma mark Event Layers

- (void)layoutSublayersOfEventsRootLayer:(CALayer *)anEventsRootLayer;

- (void)layoutSublayersOfColumnRootLayer:(CALayer *)aColumnRootLayer;

- (void)layoutSublayersOfAllDayBackgroundLayer:(WLBlockLayer *)anAllDayBackgroundLayer;

- (void)layoutSublayersOfDayBackgroundLayer:(WLBlockLayer *)aDayBackgroundLayer;

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

- (BOOL)needsUpdateColumnTitleFrame;

/*!
 @discussion    Automatically sent when:
 - Height of all day events part is changed
 - Frame is changed
 - Title of any column is changed
 - Number of columns is changed
 @see   heightOfAllDayPartOfColumn
 @see   -layoutSublayersOfRootLayer:
 @see   -_updateTitleOfColumnAtIndex:
 @see   -setColumnRootLayers:
 */
- (void)setNeedsUpdateColumnTitleFrame;

- (CGPoint)scrollPoint;

- (CGPoint)scrollPointToFocusOnDayEvents;

- (CGPoint)scrollPointToFocusOnCurrentHour;

- (BOOL)isAllDayPartOfColumnVisible;

- (CGFloat)visibleHeightOfTimeRuler;

- (CGFloat)positionForTimeIndicator;

@end


enum
{
    WLCalendarWeekViewTitleDataUnit = 1 << 0,
    WLCalendarWeekViewEventsDataUnit = 1 << 1,
    WLCalendarWeekViewColorDataUnit = 1 << 2
};

#pragma mark -

@protocol WLCalendarWeekViewDataSource

- (WLHourRange)hourRangeOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex;

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex;

- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate;

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView stringForHour:(NSUInteger)aHour;

@optional

/*!
 @discussion    You MUST pair this call with -weekViewDidAskForData:.
 */
- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView;

@end
