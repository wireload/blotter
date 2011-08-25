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
#import "WLCalendarTimeRuler.h"
#import "WLCalendarTimeRulerLayer.h"
#import "WLCalendarBackgroundLayer.h"
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarTimeIndicatorLayer.h"
#import "WLBlockLayer.h"


@protocol WLCalendarWeekViewDataSource;

@class WLCalendarTimeIndicatorLayer;


typedef struct
{
    CGFloat startHour;
    CGFloat endHour;
} WLHourRange;

static const WLHourRange WLHourRangeZero = {0.0f, 0.0f};

BOOL WLHourRangeEqualToHourRange(WLHourRange l, WLHourRange r);


@interface WLCalendarWeekView : NSView <WLCalendarTimeRuler/*, CALayerManager*/> {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat minimumHeightOfAllDayEventsPartOfColumn;
    CGFloat minimumHeightOfColumnTitle;
    BOOL showTimeIndicator;
    BOOL fitDayEvents;
    CGFloat minimumHeightOfHour;
    CGFloat maximumHeightOfHour;
    NSUInteger indexOfHighlightedColumn;

    CALayer *_rootLayer;
    CALayer *_timeRulerRootLayer;
    CALayer *_timeIndicatorRootLayer;
    __block NSMutableArray *_columnLayers;
    CGFloat _hour;
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

/*!
 @discussion Default value is 114.0f.
 */
@property CGFloat minimumHeightOfAllDayEventsPartOfColumn;

/*!
 @discussion Default value is 25.0f.
 */
@property CGFloat minimumHeightOfColumnTitle;

@property (nonatomic) BOOL showTimeIndicator;

/*!
 @discussion Default value is NO.
 */
@property (nonatomic) BOOL fitDayEvents;

/*!
 @discussion Default value is 20.0f.
 */
@property CGFloat minimumHeightOfHour;

/*!
 @discussion Default value is 100.0f.
 */
@property CGFloat maximumHeightOfHour;

@property (nonatomic) NSUInteger indexOfHighlightedColumn;

- (void)createLayers;

- (void)reloadDataAnimated:(BOOL)isAnimated;

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)showNextDay;

- (void)showNextWeek;

- (void)showNextDays:(NSUInteger)aNumberOfDays;

- (void)stopAnimations;

- (WLHourRange)eventsHourRange;

- (void)heightOfHourMayHaveChanged;


- (void)_updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)_updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)_updateColorOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)_updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTimeRuler;

- (void)_layoutTimeRulerRootLayer:(CALayer *)aRootLayer;

- (void)_layoutTimeRulerLayer:(WLCalendarTimeRulerLayer *)aTimeRulerLayer;

- (void)_layoutSublayersOfColumnLayer:(CALayer *)aColumnLayer;

- (void)_layoutDayLayer:(WLCalendarDayEventsLayer *)aDayLayer;

- (void)_layoutTimeIndicatorRootLayer:(CALayer *)aTimeIndicatorLayer;

- (void)_layoutColumnLayer:(CALayer *)aColumnLayer atIndex:(NSUInteger)anIndex;

- (void)_layoutTimeIndicatorLayer:(WLCalendarTimeIndicatorLayer *)aTimeIndicatorLayer;

- (void)_focusOnDayEvents;

- (void)_focusOnHour;

@end


@interface WLCalendarWeekView (SetupLayers)

- (CALayer *)setupRootLayer;


- (CALayer *)setupTimeRulerRootLayer;

- (WLBlockLayer *)setupTimeRulerBackgroundLayer;

- (CAScrollLayer *)setupTimeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer;


- (CALayer *)setupColumnRootLayer;

- (CALayer *)setupColumnLayer;

- (WLBlockLayer *)setupAllDayBackgroundLayer;

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer;

- (WLCalendarDayEventsLayer *)setupDayLayer;

- (CAScrollLayer *)setupDayScrollLayer;

- (WLBlockLayer *)setupDayBackgroundLayer;


- (CALayer *)setupTimeIndicatorRootLayer;

- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer;

@end


@interface CALayer (WLCalendarWeekView)

- (WLCalendarBackgroundLayer *)WL_allDayBackgroundLayer;

- (WLCalendarAllDayEventsLayer *)WL_allDayLayer;


- (WLBlockLayer *)WL_dayBackgroundLayer;

- (CAScrollLayer *)WL_dayScrollLayer;

- (WLCalendarDayEventsLayer *)WL_dayLayer;


- (CAScrollLayer *)WL_timeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)WL_timeRulerLayer;


- (WLCalendarTimeIndicatorLayer *)WL_timeIndicatorLayer;

@end


enum
{
    WLCalendarWeekViewTitleDataUnit = 1 << 0,
    WLCalendarWeekViewEventsDataUnit = 1 << 1,
    WLCalendarWeekViewColorDataUnit = 1 << 2
};


@protocol WLCalendarWeekViewDataSource

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex;

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex;

/*!
 @see -[WLCalendarTimeRuler hourForDate:].
 */
- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate;

/*!
 @see -[WLCalendarTimeRuler numberOfHours].
 */
- (NSUInteger)numberOfHoursInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView stringForHour:(NSUInteger)aHour;

@optional

- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView;

@end
