//
//  WLCalendarFloatingWeekEventsViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 21.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCalendarWeekEventsViewController.h"


typedef NS_ENUM(NSUInteger, WLTitleFormat)
{
    WLTitleFormatWeekdayOnly = 0,
    WLTitleFormatWeekdayAndMonthday = 1
};


@interface WLCalendarFloatingWeekEventsViewController : WLCalendarWeekEventsViewController

@property (nonatomic) WLTitleFormat titleFormat;

@property (nonatomic) NSInteger weekOffset;

@property (nonatomic, readonly) BOOL canShowNextWeek;

@property (nonatomic, readonly) BOOL canShowCurrentWeek;

@property (nonatomic, readonly) BOOL canShowPreviousWeek;

- (void)setTitleFormat:(WLTitleFormat)newFormat animated:(BOOL)isAnimated;

- (void)setWeekOffset:(NSInteger)newWeekOffset animated:(BOOL)isAnimated;

- (IBAction)showNextWeek:(id)aSender animated:(BOOL)isAnimated;

- (IBAction)showPreviousWeek:(id)aSender animated:(BOOL)isAnimated;

- (IBAction)showCurrentWeek:(id)aSender animated:(BOOL)isAnimated;

@end
