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


@protocol WLCalendarWeekViewDataSource;


@interface WLCalendarWeekView : NSView {
    IBOutlet NSObject<WLCalendarWeekViewDataSource> *dataSource;
    CGFloat allDayEventsHeight;

    CALayer *_rootLayer;
    CALayer *_timeRulerRootLayer;
    NSMutableArray *_weekdayRootLayers;
    CGPoint _hourPoint;
}

@property (assign) NSObject<WLCalendarWeekViewDataSource> *dataSource;

@property CGFloat allDayEventsHeight;

- (void)setupLayers;

- (void)layoutLayers;

- (void)scrollHour:(CGFloat)aHour;

- (void)updateEventsOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateTitleOfColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)updateColumnsAtIndexes:(NSIndexSet *)anIndexSet;

- (void)nextDay;

- (void)nextWeek;


- (void)_updateEventsOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateTitleOfColumnAtIndex:(NSUInteger)anIndex;

- (void)_updateColumnAtIndex:(NSUInteger)anIndex;

- (CALayer *)_setupTimeRulerLayer;

- (CALayer *)_setupWeekdayLayer;

- (NSArray *)_timeRulerScrollLayerConstraintsWithTopYMargin:(CGFloat)yMargin;

- (NSArray *)_timeRulerLayerConstraints;

- (NSArray *)_allDayEventsBackgroundLayerConstraints;

- (NSArray *)_weekdayEventsBackgrounLayerConstraints;

- (NSArray *)_weekdayTitleLayerConstraints;

- (NSArray *)_weekdayEventsLayerConstraints;

- (NSArray *)_weekdayEventsScrollLayerConstraintsWithTopYMargin:(CGFloat)yMargin;

- (void)_layoutWeekdayRootLayer:(CALayer *)aRootLayer;

- (void)_positionWeekdayRootLayer:(CALayer *)aRootLayer atIndex:(NSUInteger)anIndex;

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

@end