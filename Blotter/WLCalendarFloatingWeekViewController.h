//
//  WLCalendarNextWeekViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 04.01.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCalendarWeekViewController.h"


typedef enum
{
    WLCalendarWeekViewWeekMode,
    WLCalendarWeekViewDayMode
} WLCalendarWeekViewMode;


@interface WLCalendarFloatingWeekViewController : WLCalendarWeekViewController {
    WLCalendarWeekViewMode mode;
    NSInteger weeksOffset;
}

/*!
 @discussion    Default value is WLCalendarWeekViewWeekMode.
 Resets weeksOffset to 0.
 */
@property (nonatomic) WLCalendarWeekViewMode mode;

/*!
 @discussion    Default value is 0.
 */
@property (nonatomic) NSInteger weeksOffset;

@property (nonatomic, readonly) BOOL canShowNextWeek;

@property (nonatomic, readonly) BOOL canShowCurrentWeek;

@property (nonatomic, readonly) BOOL canShowPreviousWeek;

- (IBAction)showNextWeek:(id)aSender;

- (IBAction)showPreviousWeek:(id)aSender;

- (IBAction)showCurrentWeek:(id)aSender;

@end


@interface NSDate (WLCalendarFloatingWeekViewController)

- (NSInteger)WL_numberOfDaysToDate:(NSDate *)aDate calendar:(NSCalendar *)aCalendar;

@end
