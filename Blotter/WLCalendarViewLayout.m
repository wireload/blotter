//
//  WLCalendarViewLayout.m
//  Blotter
//
//  Created by Ilya Kulakov on 5/2/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import "WLCalendarViewLayout.h"

#import "NSUserDefaults+WLApplicationDefaults.h"


static const CGFloat _WLSpacingAfterInfoView = 17.0;

static const CGFloat _WLSpacingAfterDateView = 10.0;

static const CGFloat _WLSpacingAfterRemindersView = 10.0;

static const CGFloat _WLSpacingAfterAllDayEventsView = 8.0;


@implementation WLCalendarViewLayout

- (instancetype)initWithBounds:(NSRect)aBounds
                 forParentView:(NSView *)aParentView
               withPreferences:(nullable NSDictionary *)aPreferences
{
    self = [super init];

    if (!self)
        return nil;

    if (!aPreferences)
        aPreferences = (NSDictionary *)NSUserDefaults.standardUserDefaults;

    _owningView = aParentView;

    _minInfoWidth = [[aPreferences objectForKey:WLMinimumDateViewWidthtKey] doubleValue];
    _minDateHeight = [[aPreferences objectForKey:WLMinimumDateViewHeightKey] doubleValue];
    _minRemindersHeight = [[aPreferences objectForKey:WLMinimumTasksViewHeightKey] doubleValue];
    _minRightNowHeight = [[aPreferences objectForKey:WLMinimumRightNowViewHeightKey] doubleValue];

    _minWeekWidth = [[aPreferences objectForKey:WLMinimumWeekViewWidthKey] doubleValue];
    _minAllDayEventsHeight = 50.0;
    _minDayEventsHeight = [[aPreferences objectForKey:WLMinimumWeekViewHeightKey] doubleValue] - _minAllDayEventsHeight;

    CGFloat prefInfoWidth = [[aPreferences objectForKey:WLInfoViewsWidthKey] doubleValue];
    CGFloat prefDateHeight = [[aPreferences objectForKey:WLDateViewHeightKey] doubleValue];
    CGFloat prefRemindersHeight = [[aPreferences objectForKey:WLTasksViewHeightKey] doubleValue];
    CGFloat prefAllDayHeight = [[aPreferences objectForKey:WLAllDayViewHeightKey] doubleValue];
    WLCalendarLayout prefLayout = [[aPreferences objectForKey:WLCalendarLayoutKey] unsignedIntegerValue];
    BLSize prefSize = [[aPreferences objectForKey:WLCalendarSizeKey] unsignedIntegerValue];

    /*!
     Split space into 2 parts, in order, prioritizing the first part.

     @param outSizeA Size of A.

     @param outSizeB Size of B.

     @param outMinSizeA Min possible size for A.

     @param outMaxSizeA Max possible size for A.

     @param outCanFitA Whether there is enough space to fit A.

     @param outCanFitB Whether there is enough space to fit B.
     */
    __auto_type SplitSpace = ^(CGFloat aTotalSpace,

                               CGFloat aMinSizeA,
                               CGFloat aPrefSizeA,
                               CGFloat * _Nonnull outSizeA,

                               CGFloat aSpacing,

                               CGFloat aMinSizeB,
                               CGFloat * _Nonnull outSizeB,

                               BOOL * _Nonnull outCanFitA,
                               BOOL * _Nonnull outCanFitB)
    {
        CGFloat remainingSize = aTotalSpace;
        CGFloat sizeA = fmin(aPrefSizeA, remainingSize);
        BOOL canShowA = sizeA >= aMinSizeA;

        if (canShowA)
            remainingSize -= sizeA;
        else
            sizeA = 0.0;

        CGFloat sizeB = remainingSize - aSpacing;
        BOOL canShowB = sizeB >= aMinSizeB;

        if (!canShowB)
        {
            sizeB = 0.0;

            if (canShowA)
                sizeA += remainingSize;
        }

        NSCParameterAssert(canShowA || sizeA == 0.0);
        NSCParameterAssert(canShowB || sizeB == 0.0);
        NSCParameterAssert(sizeA >= 0.0 && sizeA <= aTotalSpace);
        NSCParameterAssert(sizeB >= 0.0 && sizeB <= aTotalSpace);
        NSCParameterAssert(!canShowA || !canShowB || (sizeA + aSpacing + sizeB) == aTotalSpace);

        *outSizeA = sizeA;
        *outSizeB = sizeB;

        BOOL canFitA = aMinSizeA <= aTotalSpace;
        BOOL canFitB = aMinSizeB <= aTotalSpace;

        *outCanFitA = canFitA;
        *outCanFitB = canFitB;
    };

    _bounds = aBounds;

    CGFloat defaultInfoWidth = [[[NSUserDefaults.standardUserDefaults volatileDomainForName:NSRegistrationDomain] objectForKey:WLInfoViewsWidthKey] doubleValue];

    SplitSpace(NSWidth(aBounds),

               _minInfoWidth,
               prefLayout == WLCalendarLayoutCustom ? prefInfoWidth : defaultInfoWidth,
               &_infoWidth,

               _WLSpacingAfterInfoView,

               // When size is Narrow, Week is excluded by setting its min size to a value
               // that cannot be satisfied.
               prefSize != BLNarrowSize ? _minWeekWidth : NSWidth(aBounds) + 1.0,
               &_weekWidth,

               &_canFitInfo,
               &_canFitWeek);

    // RRN = Reminders or Right Now.
    CGFloat minRRNHeight = fmin(_minRemindersHeight, _minRightNowHeight);
    CGFloat rrnHeight = 0.0;
    BOOL canFitRRN = NO;
    SplitSpace(NSHeight(aBounds),

               _minDateHeight,
               prefDateHeight,
               &_dateHeight,

               _WLSpacingAfterDateView,

               minRRNHeight,
               &rrnHeight,

               &_canFitDate,
               &canFitRRN);

    switch (prefLayout)
    {
        case WLCalendarLayoutNormal:
            SplitSpace(rrnHeight,

                       _minRemindersHeight,
                       fdim(rrnHeight, _WLSpacingAfterRemindersView) / 2.0,
                       &_remindersHeight,

                       _WLSpacingAfterRemindersView,

                       _minRightNowHeight,
                       &_rightNowHeight,

                       &_canFitReminders,
                       &_canFitRightNow);
            break;
        case WLCalendarLayoutCustom:
            SplitSpace(rrnHeight,

                       _minRemindersHeight,
                       prefRemindersHeight,
                       &_remindersHeight,

                       _WLSpacingAfterRemindersView,

                       _minRightNowHeight,
                       &_rightNowHeight,

                       &_canFitReminders,
                       &_canFitRightNow);
            break;
        case WLCalendarLayoutToDo:
            SplitSpace(rrnHeight,

                       _minRemindersHeight,
                       rrnHeight,
                       &_remindersHeight,

                       _WLSpacingAfterRemindersView,

                       _minRightNowHeight,
                       &_rightNowHeight,

                       &_canFitReminders,
                       &_canFitRightNow);
            NSParameterAssert(_rightNowHeight == 0.0);
            break;
        case WLCalendarLayoutRightNow:
            SplitSpace(rrnHeight,

                       _minRemindersHeight,
                       0.0,
                       &_remindersHeight,

                       _WLSpacingAfterRemindersView,

                       _minRightNowHeight,
                       &_rightNowHeight,

                       &_canFitReminders,
                       &_canFitRightNow);
            NSParameterAssert(_remindersHeight == 0.0);
            break;
    }

    SplitSpace(NSHeight(aBounds),

               _minAllDayEventsHeight,
               prefAllDayHeight,
               &_allDayEventsHeight,

               _WLSpacingAfterAllDayEventsView,
               _minDayEventsHeight,
               &_dayEventsHeight,

               &_canFitAllDayEvents,
               &_canFitDayEvents);

    _spacingAfterInfo = _WLSpacingAfterInfoView;
    _spacingAfterDate = _WLSpacingAfterDateView;
    _spacingAfterReminders = _WLSpacingAfterRemindersView;
    _spacingAfterAllDayEvents = _WLSpacingAfterAllDayEventsView;

    _canFitInfoAndWeek = (_minInfoWidth + _spacingAfterInfo + _minWeekWidth) <= NSWidth(aBounds);
    _canFitDateRemindersAndRightNow = (_minDateHeight + _spacingAfterDate + _minRemindersHeight + _spacingAfterReminders + _minRightNowHeight) <= NSHeight(aBounds);
    _canFitDateAndReminders = (_minDateHeight + _spacingAfterDate + _minRemindersHeight) <= NSHeight(aBounds);
    _canFitDateAndRightNow = (_minDateHeight + _spacingAfterDate + _minRightNowHeight) <= NSHeight(aBounds);
    _canFitRemindersAndRightNow = (_minRemindersHeight + _spacingAfterReminders + _minRightNowHeight) <= NSHeight(aBounds);
    _canFitAllDayAndDayEvents = (_minAllDayEventsHeight + _spacingAfterAllDayEvents + _minDayEventsHeight) <= NSHeight(aBounds);

    return self;
}

#pragma mark Properties

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsInfoCollapsed
{
    return [NSSet setWithObject:@"infoWidth"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsDateCollapsed
{
    return [NSSet setWithObject:@"dateHeight"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsRemindersCollapsed
{
    return [NSSet setWithObject:@"remindersHeight"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsRightNowCollapsed
{
    return [NSSet setWithObject:@"rightNowHeight"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsWeekCollapsed
{
    return [NSSet setWithObject:@"weekWidth"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsAllDayEventsCollapsed
{
    return [NSSet setWithObject:@"allDayEventsHeight"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsDayEventsCollapsed
{
    return [NSSet setWithObject:@"dayEventsHeight"];
}

- (BOOL)isInfoCollapsed
{
    return _infoWidth == 0.0;
}

- (BOOL)isDateCollapsed
{
    return _dateHeight == 0.0;
}

- (BOOL)isRemindersCollapsed
{
    return _remindersHeight == 0.0;
}

- (BOOL)isRightNowCollapsed
{
    return _rightNowHeight == 0.0;
}

- (BOOL)isWeekCollapsed
{
    return _weekWidth == 0.0;
}

- (BOOL)isAllDayEventsCollapsed
{
    return _allDayEventsHeight == 0.0;
}

- (BOOL)isDayEventsCollapsed
{
    return _dayEventsHeight == 0.0;
}

@end
