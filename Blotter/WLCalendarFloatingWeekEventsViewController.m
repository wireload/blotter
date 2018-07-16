//
//  WLCalendarFloatingWeekEventsViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 21.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarFloatingWeekEventsViewController.h"
#import "NSDate+WLDayBoundaries.h"


@implementation WLCalendarFloatingWeekEventsViewController
{
    NSDateFormatter *_titleFormatter;
}

- (instancetype)initWithNibName:(NSString *)aNibNameOrNil bundle:(NSBundle *)aNibBundleOrNil
{
    self = [super initWithNibName:aNibNameOrNil bundle:aNibBundleOrNil];

    if (self)
    {
        _titleFormatter = [[NSDateFormatter alloc] init];
    }

    return self;
}


#pragma mark Properties
@dynamic view;

+ (NSSet *)keyPathsForValuesAffectingCanShowNextWeek
{
    return [NSSet setWithObject:@"weekOffset"];
}

+ (NSSet *)keyPathsForValuesAffectingCanShowCurrentWeek
{
    return [NSSet setWithObject:@"weekOffset"];
}

+ (NSSet *)keyPathsForValuesAffectingCanShowPreviousWeek
{
    return [NSSet setWithObject:@"weekOffset"];
}

- (void)setTitleFormat:(WLTitleFormat)newTitleFormat
{
    [self setTitleFormat:newTitleFormat animated:NO];
}

- (NSInteger)weekOffset
{
    return self.numberOfOffsetUnits;
}

- (void)setWeekOffset:(NSInteger)newWeekOffset
{
    [self setWeekOffset:newWeekOffset animated:NO];
}

- (BOOL)canShowNextWeek
{
    return self.weekOffset != NSIntegerMax;
}

- (BOOL)canShowCurrentWeek
{
    return self.weekOffset != 0;
}

- (BOOL)canShowPreviousWeek
{
    return self.weekOffset != NSIntegerMin;
}


#pragma mark Methods

- (void)setTitleFormat:(WLTitleFormat)newFormat animated:(BOOL)isAnimated
{
    _titleFormat = newFormat;
    [self updateDerivativeProperties];

    if (self.isViewLoaded)
        [self.view updateTitleOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfColumns)] animated:isAnimated];
}

- (void)setWeekOffset:(NSInteger)newWeekOffset animated:(BOOL)isAnimated
{
    [self setOffsetUnit:NSCalendarUnitWeekOfMonth number:newWeekOffset animated:isAnimated];
}

- (IBAction)showNextWeek:(id)aSender animated:(BOOL)isAnimated
{
    if (self.canShowNextWeek)
        [self setWeekOffset:self.weekOffset + 1 animated:isAnimated];
}

- (IBAction)showCurrentWeek:(id)aSender animated:(BOOL)isAnimated
{
    if (self.canShowCurrentWeek)
        [self setWeekOffset:0 animated:isAnimated];
}

- (IBAction)showPreviousWeek:(id)aSender animated:(BOOL)isAnimated
{
    if (self.canShowPreviousWeek)
        [self setWeekOffset:self.weekOffset - 1 animated:isAnimated];
}


#pragma mark WLCalendarWeekViewDataSource

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView titleForColumnAtIndex:(NSUInteger)anIndex
{
    return [_titleFormatter stringFromDate:[self dateForColumnAtIndex:anIndex]];
}

- (BOOL)weekView:(WLCalendarWeekView *)aWeekView highlightsTitleForColumnAtIndex:(NSUInteger)anIndex
{
    return anIndex == [self indexOfColumnForDate:self.date];
}


#pragma mark WLCalendarWeekEventsViewController

- (void)updateDerivativeProperties
{
    [super updateDerivativeProperties];

    switch (_titleFormat)
    {
        case WLTitleFormatWeekdayAndMonthday:
            _titleFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"eeedMMM" options:0 locale:_calendar.locale];
            break;
        case WLTitleFormatWeekdayOnly:
        default:
            _titleFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:_calendar.locale];
            break;
    }

    _titleFormatter.calendar = _calendar;
    _titleFormatter.locale = _calendar.locale;
}


#pragma mark NSViewController

- (void)setView:(WLCalendarWeekView *)newView
{
    super.view = newView;
    self.view.fitsDayEvents = YES;
}

@end
