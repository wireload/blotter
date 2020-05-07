//
//  WLCalendarViewLayout.h
//  Blotter
//
//  Created by Ilya Kulakov on 5/2/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Layout configurationg of the calendar view.
 */
@interface WLCalendarViewLayout : NSObject

@property CGFloat spacingAfterInfo;

@property CGFloat spacingAfterDate;

@property CGFloat spacingAfterReminders;

@property CGFloat spacingAfterAllDayEvents;


@property (readonly) CGFloat minInfoWidth;

@property (readonly) CGFloat minDateHeight;

@property (readonly) CGFloat minRemindersHeight;

@property (readonly) CGFloat minRightNowHeight;

@property (readonly) CGFloat minWeekWidth;

@property (readonly) CGFloat minAllDayEventsHeight;

@property (readonly) CGFloat minDayEventsHeight;


@property (readonly) CGFloat boundsWidth;

@property (readonly) CGFloat boundsHeight;


@property CGFloat infoWidth;

@property CGFloat dateHeight;

@property CGFloat remindersHeight;

@property CGFloat rightNowHeight;

@property CGFloat weekWidth;

@property CGFloat allDayEventsHeight;

@property CGFloat dayEventsHeight;


@property (readonly) BOOL canFitInfo;

@property (readonly) BOOL canFitDate;

@property (readonly) BOOL canFitReminders;

@property (readonly) BOOL canFitRightNow;

@property (readonly) BOOL canFitWeek;

@property (readonly) BOOL canFitAllDayEvents;

@property (readonly) BOOL canFitDayEvents;


@property (readonly) BOOL canFitInfoAndWeek;

@property (readonly) BOOL canFitDateRemindersAndRightNow;

@property (readonly) BOOL canFitDateAndReminders;

@property (readonly) BOOL canFitDateAndRightNow;

@property (readonly) BOOL canFitRemindersAndRightNow;

@property (readonly) BOOL canFitAllDayAndDayEvents;


@property (readonly) BOOL isInfoCollapsed;

@property (readonly) BOOL isDateCollapsed;

@property (readonly) BOOL isRemindersCollapsed;

@property (readonly) BOOL isRightNowCollapsed;

@property (readonly) BOOL isWeekCollapsed;

@property (readonly) BOOL isAllDayEventsCollapsed;

@property (readonly) BOOL isDayEventsCollapsed;

/*!
 @param aBounds Bounding rectangle for the layout.

 @param aParentView Parent view where the layout will be applied.

 @param aPreferences Dict-like object with layout preferences.
 */
- (instancetype)initWithBounds:(NSRect)aBounds
                 forParentView:(NSView *)aParentView
               withPreferences:(nullable NSDictionary *)aPreferences;

@end

NS_ASSUME_NONNULL_END
