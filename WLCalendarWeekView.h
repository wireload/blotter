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


@interface WLCalendarWeekView : NSView /*<CALayerManager>*/ {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat allDayEventsHeight;
    BOOL showTimeIndicator;

    CALayer *_rootLayer;
    CALayer *_timeRulerRootLayer;
    WLCalendarTimeIndicatorLayer *_timeIndicatorLayer;
    NSMutableArray *_columnLayers;
    CGFloat _hour;
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

@property CGFloat allDayEventsHeight;

@property (nonatomic) BOOL showTimeIndicator;

- (void)setupLayersAnimated:(BOOL)isAnimated;

- (void)scrollHour:(CGFloat)aHour animated:(BOOL)isAnimated;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)showNextDay;

- (void)showNextWeek;


- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColorOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColumnAtIndex:(NSUInteger)anIndex;

- (void)_layoutTimerRulerRootlayer:(CALayer *)aRootLayer;

- (void)_layoutColumnLayer:(CALayer *)aRootLayer;

- (void)_positionColumnLayer:(CALayer *)aRootLayer atIndex:(NSUInteger)anIndex;

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

enum
{
    WLCalendarWeekViewTitleDataUnit = 1 << 0,
    WLCalendarWeekViewEventsDataUnit = 1 << 1
};

@protocol WLCalendarWeekViewDataSource<WLCalendarTimeRuler>

- (NSString *)stringForHour:(NSUInteger)aHour;

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView;

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex;

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex;

- (void)weekViewDidSetupLayers:(WLCalendarWeekView *)aWeekView;

@optional

- (void)weekView:(WLCalendarWeekView *)aWeekView willAskForData:(NSUInteger)dataUnits forColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)weekViewDidAskForData:(WLCalendarWeekView *)aWeekView;

- (CGColorRef)weekView:(WLCalendarWeekView *)aWeekView colorForColumnAtIndex:(NSUInteger)anIndex;

@end