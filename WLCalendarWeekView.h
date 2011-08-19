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


@protocol WLCalendarWeekViewDataSource;

@class WLCalendarTimeIndicatorLayer;


typedef struct
{
    CGFloat startHour;
    CGFloat endHour;
} WLHourRange;


@interface WLCalendarWeekView : NSView <WLCalendarTimeRuler/*, CALayerManager*/> {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat minimumHeightOfAllDayEventsPartOfColumn;
    BOOL showTimeIndicator;
    BOOL fitDayEvents;
    CGFloat minimumHeightOfHour;
    CGFloat maximumHeightOfHour;

    CALayer *_rootLayer;
    CALayer *_timeRulerRootLayer;
    WLCalendarTimeIndicatorLayer *_timeIndicatorLayer;
    __block NSMutableArray *_columnLayers;
    CGFloat _hour;
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

/*!
 @discussion Default value is 100.0f.
 */
@property CGFloat minimumHeightOfAllDayEventsPartOfColumn;

@property (nonatomic) BOOL showTimeIndicator;

/*!
 @discussion Default value is NO.
 */
@property BOOL fitDayEvents;

/*!
 @discussion Default value is 20.0f.
 */
@property CGFloat minimumHeightOfHour;

/*!
 @discussion Default value is 100.0f.
 */
@property CGFloat maximumHeightOfHour;

- (void)setupLayersAnimated:(BOOL)isAnimated;

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)showNextDay;

- (void)showNextWeek;

- (void)showNextDays:(NSUInteger)aNumberOfDays;

- (void)stopAnimations;

- (WLHourRange)eventsHourRange;

- (void)eventsDidUpdated;


- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTimeRuler;

- (void)_layoutTimeRulerRootLayer:(CALayer *)aRootLayer;

- (void)_layoutTimeRulerLayer:(WLCalendarTimeRulerLayer *)aTimeRulerLayer;

- (void)_layoutColumnLayer:(CALayer *)aColumnLayer;

- (void)_layoutDayLayer:(WLCalendarDayEventsLayer *)aDayLayer;

- (void)_positionColumnLayer:(CALayer *)aColumnLayer atIndex:(NSUInteger)anIndex;

@end


@interface WLCalendarWeekView (SetupLayers)

- (CALayer *)setupRootLayer;


- (CALayer *)setupTimeRulerRootLayer;

- (WLCalendarBackgroundLayer *)setupTimeRulerBackgroundLayer;

- (CAScrollLayer *)setupTimeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)setupTimeRulerLayer;


- (CALayer *)setupColumnRootLayer;

- (CALayer *)setupColumnLayer;

- (WLCalendarBackgroundLayer *)setupAllDayBackgroundLayer;

- (WLCalendarAllDayEventsLayer *)setupAllDayLayer;

- (WLCalendarDayEventsLayer *)setupDayLayer;

- (CAScrollLayer *)setupDayScrollLayer;

- (CATextLayer *)setupDayTitleLayer;

- (WLCalendarBackgroundLayer *)setupDayBackgroundLayer;


- (WLCalendarTimeIndicatorLayer *)setupTimeIndicatorLayer;

@end


@interface CALayer (WLCalendarWeekView)

- (WLCalendarBackgroundLayer *)WL_allDayBackgroundLayer;

- (WLCalendarAllDayEventsLayer *)WL_allDayLayer;


- (WLCalendarBackgroundLayer *)WL_dayBackgroundLayer;

- (CAScrollLayer *)WL_dayScrollLayer;

- (WLCalendarDayEventsLayer *)WL_dayLayer;

- (CATextLayer *)WL_titleLayer;


- (CAScrollLayer *)WL_timeRulerScrollLayer;

- (WLCalendarTimeRulerLayer *)WL_timeRulerLayer;

@end


enum
{
    WLCalendarWeekViewTitleDataUnit = 1 << 0,
    WLCalendarWeekViewEventsDataUnit = 1 << 1
};


@protocol WLCalendarWeekViewDataSource

- (NSString *)stringForHour:(NSUInteger)aHour;

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex;

- (void)weekViewDidSetupLayers:(WLCalendarWeekView *)aWeekView;

/*!
 @see -[WLCalendarTimeRuler hourForDate:].
 */
- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate;

/*!
 @see -[WLCalendarTimeRuler numberOfHours].
 */
- (NSUInteger)numberOfHoursInWeekView:(WLCalendarWeekView *)aWeekView;

@optional

- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView;

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex;

@end
