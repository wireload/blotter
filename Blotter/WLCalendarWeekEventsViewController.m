//
//  WLCalendarWeekEventsViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 20.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import "WLCalendarWeekEventsViewController.h"
#import "WLCalendarEventsStorage.h"
#import "NSDate+WLDayBoundaries.h"


@interface WLCalendarWeekEventsViewController (/* Private */)

@property (copy) NSDate *dateOfFirstColumn;

@property (readwrite) NSUInteger numberOfColumns;

@property (copy) WLDateRange *dateRangeOfColumns;

@property (readwrite) CGFloat hour;

@end


@implementation WLCalendarWeekEventsViewController
{
    WLCalendarEventsStorage *_storage;

    WLHourRange _hourRange;
    NSDateFormatter *_timeFormatter;

    WLLog *_log;
}

- (instancetype)initWithNibName:(NSString *)aNibNameOrNil bundle:(NSBundle *)aNibBundleOrNil
{
    self = [super initWithNibName:aNibNameOrNil bundle:aNibBundleOrNil];

    if (self)
    {
        _alignmentUnit = NSCalendarUnitWeekOfMonth;
        _offsetUnit = NSCalendarUnitWeekOfMonth;

        _numberOfAlignmentUnits = 1;
        _timeFormatter = [[NSDateFormatter alloc] init];
        _log = [[WLLog alloc] initWithName:@"net.wireload.blotter.mac.WLCalendarWeekEventsViewController"];
    }

    return self;
}

- (void)dealloc
{
    [self.representedObject removeObservedDateRange:self.dateRangeOfColumns];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Properties
@dynamic view;

+ (BOOL)automaticallyNotifiesObserversOfDateRangeOfColumns
{
    return NO;
}

- (void)setCalendar:(NSCalendar *)newCalendar
{
    [self setCalendar:newCalendar animated:NO];
}

- (void)setDate:(NSDate *)newDate
{
    [self setDate:newDate animated:NO];
}


#pragma mark Methods

- (void)setCalendar:(NSCalendar *)newCalendar animated:(BOOL)isAnimated
{
    _calendar = newCalendar;
    [self updateDerivativeProperties];
    _storage = [[WLCalendarEventsStorage alloc] initWithEvents:_storage != nil ? _storage.events : @[]
                                                      calendar:_calendar
                                                          unit:NSCalendarUnitDay];

    if (self.isViewLoaded)
    {
        if (isAnimated)
        {
            [CATransaction begin];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [CATransaction setAnimationDuration:0.25];
        }

        [self.view reloadDataAnimated:isAnimated];
        [self.view scrollHour:self.hour animated:isAnimated];

        if (isAnimated)
            [CATransaction commit];
    }
}

- (void)setDate:(NSDate *)newDate animated:(BOOL)isAnimated
{
    _date = newDate;
    [self updateDerivativePropertiesAndMoveIfNeeded:isAnimated];
}

- (void)setOffsetUnit:(NSCalendarUnit)newOffsetUnit number:(NSInteger)newNumberOfUnits animated:(BOOL)isAnimated
{
    _offsetUnit = newOffsetUnit;
    _numberOfOffsetUnits = newNumberOfUnits;
    [self updateDerivativePropertiesAndMoveIfNeeded:isAnimated];
}

- (void)setAlignmentUnit:(NSCalendarUnit)newAlignmentUnit number:(NSUInteger)newNumberOfUnits animated:(BOOL)isAnimated
{
    _alignmentUnit = newAlignmentUnit;
    _numberOfAlignmentUnits = newNumberOfUnits;
    [self updateDerivativePropertiesAndMoveIfNeeded:isAnimated];
}

- (NSDate *)dateForColumnAtIndex:(NSUInteger)anIndex
{
    if (!_calendar || !self.dateOfFirstColumn || anIndex > self.numberOfColumns)
        return nil;

    NSDateComponents *columnDateComponents = [[NSDateComponents alloc] init];
    columnDateComponents.day = (NSInteger)anIndex;
    return [[_calendar dateByAddingComponents:columnDateComponents toDate:self.dateOfFirstColumn options:0] WL_noon:_calendar];
}

- (NSUInteger)indexOfColumnForDate:(NSDate *)aDate
{
    if (!_calendar || !self.dateOfFirstColumn || [self.dateRangeOfColumns positionOfDate:aDate] != WLWithinRange)
        return NSNotFound;

    WLDateRange *r = [WLDateRange dateRangeWithStartDate:self.dateOfFirstColumn endDate:aDate];
    r = [r dateRangeByAligningCalendarUnit:NSCalendarUnitDay calendar:_calendar options:WLAlignStartDateOutward | WLAlignEndDateInward];
    return [self numberOfColumnsForCalendar:_calendar dateRangeOfColumns:r];
}

- (NSDate *)makeDateOfFirstColumnForCalendar:(NSCalendar *)aCalendar
                                        date:(NSDate *)aDate
                                  offsetUnit:(NSCalendarUnit)anOffsetUnit
                         numberOfOffsetUnits:(NSInteger)aNumberOfOffsetUnits
                               alignmentUnit:(NSCalendarUnit)anAlignmentUnit
{
    NSDate *newDateOfFirstColumn = nil;

    if (aCalendar && aDate)
    {
        NSDateComponents *c = [[NSDateComponents alloc] init];

        if (self.numberOfOffsetUnits)
            [c setValue:aNumberOfOffsetUnits forComponent:anOffsetUnit];

        NSDate *effectiveDate = [aCalendar dateByAddingComponents:c toDate:aDate options:0];
        [aCalendar rangeOfUnit:anAlignmentUnit startDate:&newDateOfFirstColumn interval:NULL forDate:effectiveDate];
        newDateOfFirstColumn = [newDateOfFirstColumn WL_noon:aCalendar];
    }

    return newDateOfFirstColumn;
}

- (WLDateRange *)makeDateRangeOfColumnsForCalendar:(NSCalendar *)aCalendar
                                 dateOfFirstColumn:(NSDate *)aDateOfFirstColumn
                                     alignmentUnit:(NSCalendarUnit)anAlignmentUnit
                            numberOfAlignmentUnits:(NSUInteger)aNumberOfAlignmentUnits
{
    WLDateRange *newDateRangeOfColumns = nil;

    if (aCalendar && aDateOfFirstColumn)
    {
        NSDateComponents *c = [[NSDateComponents alloc] init];
        [c setValue:(NSInteger)aNumberOfAlignmentUnits forComponent:anAlignmentUnit];
        NSDate *dateOfLastColumn = [aCalendar dateByAddingComponents:c toDate:aDateOfFirstColumn options:0];
        newDateRangeOfColumns = [WLDateRange dateRangeWithStartDate:aDateOfFirstColumn endDate:dateOfLastColumn];
        newDateRangeOfColumns = [newDateRangeOfColumns dateRangeByAligningCalendarUnit:NSCalendarUnitDay
                                                                              calendar:aCalendar
                                                                               options:WLAlignStartDateOutward | WLAlignEndDateInward];
    }

    return newDateRangeOfColumns;
}

- (NSUInteger)numberOfColumnsForCalendar:(NSCalendar *)aCalendar dateRangeOfColumns:(WLDateRange *)aDateRangeOfColumns
{
    NSUInteger newNumberOfColumns = 0;

    if (aCalendar && aDateRangeOfColumns)
    {
        newNumberOfColumns = (NSUInteger)[aCalendar components:NSCalendarUnitDay
                                                      fromDate:aDateRangeOfColumns.startDate
                                                        toDate:aDateRangeOfColumns.endDate
                                                       options:0].day;
    }

    return newNumberOfColumns;
}

- (CGFloat)hourForCalendar:(NSCalendar *)aCalendar date:(NSDate *)aDate
{
    NSDateComponents *components = [aCalendar components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                fromDate:aDate];
    CGFloat newHour = components.hour;
    NSRange minutesRange = [aCalendar rangeOfUnit:NSCalendarUnitMinute inUnit:NSCalendarUnitHour forDate:aDate];
    newHour += (CGFloat)components.minute / minutesRange.length;
    return newHour;
}

- (void)updateDerivativeProperties
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"%@ MUST be called on the Main Thread", NSStringFromSelector(_cmd));

    self.dateOfFirstColumn = [self makeDateOfFirstColumnForCalendar:_calendar
                                                               date:self.date
                                                         offsetUnit:self.offsetUnit
                                                numberOfOffsetUnits:self.numberOfOffsetUnits
                                                      alignmentUnit:self.alignmentUnit];

    [self willChangeValueForKey:@"dateRangeOfColumns"];
    [self.representedObject removeObservedDateRange:self.dateRangeOfColumns];
    self.dateRangeOfColumns = [self makeDateRangeOfColumnsForCalendar:_calendar
                                                    dateOfFirstColumn:_dateOfFirstColumn
                                                        alignmentUnit:self.alignmentUnit
                                               numberOfAlignmentUnits:self.numberOfAlignmentUnits];
    self.numberOfColumns = [self numberOfColumnsForCalendar:self.calendar dateRangeOfColumns:self.dateRangeOfColumns];
    [self.representedObject addObservedDateRange:self.dateRangeOfColumns];
    [self didChangeValueForKey:@"dateRangeOfColumns"];

    self.hour = [self hourForCalendar:_calendar date:self.date];

    // _hourRange
    NSRange r = [_calendar maximumRangeOfUnit:NSCalendarUnitHour];
    _hourRange = WLHourRangeMake(r.location, NSMaxRange(r));

    // _timeFormatter
    _timeFormatter.calendar = _calendar;
    _timeFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"j:mm" options:0 locale:_calendar.locale];
}

- (void)updateDerivativePropertiesAndMoveIfNeeded:(BOOL)isAnimated
{
    NSDate *oldDateOfFirstColumn = self.dateOfFirstColumn;
    NSUInteger oldNumberOfColumns = self.numberOfColumns;
    [self updateDerivativeProperties];

    if (self.isViewLoaded)
    {
        // Update storage for smooth animations.
        // If we had relied on background fetching, events would jump during animation.
        _storage = [[WLCalendarEventsStorage alloc] initWithEvents:[self.representedObject calEventsForDateRange:self.dateRangeOfColumns] calendar:_calendar unit:NSCalendarUnitDay];

        if (isAnimated)
        {
            [CATransaction begin];
            [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [CATransaction setAnimationDuration:0.25];
        }

        WLDateRange *r = [WLDateRange dateRangeWithStartDate:oldDateOfFirstColumn endDate:self.dateOfFirstColumn];
        r = [r dateRangeByAligningCalendarUnit:NSCalendarUnitDay calendar:_calendar options:WLAlignStartDateOutward | WLAlignEndDateInward];
        NSUInteger numberOfColumns = [self numberOfColumnsForCalendar:_calendar dateRangeOfColumns:r];

        if (numberOfColumns > 0)
        {
            NSUInteger show = 0;
            NSUInteger hide = numberOfColumns;

            if (numberOfColumns >= oldNumberOfColumns)
            {
                show = self.numberOfColumns;
                hide = oldNumberOfColumns;
            }
            else if (oldNumberOfColumns <= self.numberOfColumns)
                show = (self.numberOfColumns - oldNumberOfColumns) + numberOfColumns;

            [self.view showDays:show
                       hideDays:hide
                      direction:[oldDateOfFirstColumn compare:self.dateOfFirstColumn] == NSOrderedAscending ? WLRightToLeftDirection : WLLeftToRightDirection
                       animated:isAnimated];
        }

        [self.view scrollHour:self.hour animated:isAnimated];
        [self.view updateHighlightsTitleOfColumnsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfColumns)] animated:isAnimated];
        self.view.showsTimeIndicator = self.numberOfOffsetUnits == 0;

        if (isAnimated)
            [CATransaction commit];
    }
}

- (void)eventsDidChange:(NSNotification *)aNotification
{
    WLDateRange *localRepresentedDateRange = [self.dateRangeOfColumns copy];

    if (localRepresentedDateRange == nil)
        return;

    WLCalendarEventsController *localRepresentedObject = aNotification.object;
    NSArray *events = aNotification.userInfo[localRepresentedDateRange];

    if (events)
    {
        NSCalendar *localRepresentedCalendar = [_calendar copy];
        __block WLCalendarEventsStorage *s = [[WLCalendarEventsStorage alloc] initWithEvents:events
                                                                                    calendar:localRepresentedCalendar
                                                                                        unit:NSCalendarUnitDay];
        dispatch_async(dispatch_get_main_queue(), ^
        {
            // Events become invalid when Represented Object is changed.
            if (self.representedObject == localRepresentedObject)
            {
                // Events may become unaligned when Represented Calendar is changed.
                if (self->_calendar != localRepresentedCalendar)
                    s = [[WLCalendarEventsStorage alloc] initWithEvents:s.events calendar:self->_calendar unit:NSCalendarUnitDay];

                // Events become invalid when Represented Date Range is changed.
                if ([localRepresentedDateRange isEqual:self.dateRangeOfColumns])
                {
                    self->_storage = s;

                    [self->_log logDebugWithMessenger:^
                    {
                        return [NSString stringWithFormat:@"New Events Storage (%@): %@", self, s];
                    }];

                    if (self.isViewLoaded)
                    {
                        NSIndexSet *allColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.numberOfColumns)];
                        [self.view updateEventsOfColumnsAtIndexes:allColumnIndexes animated:YES];
                    }
                }
            }
        });
    }
}


#pragma mark WLCalendarWeekViewDataSource

- (WLHourRange)hourRangeOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    return _hourRange;
}

- (CGFloat)weekView:(WLCalendarWeekView *)aWeekView convertDateToHour:(NSDate *)aDate
{
    NSParameterAssert(_calendar != nil);

    NSDateComponents *c = [_calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:aDate];
    NSRange minutesRange = [_calendar rangeOfUnit:NSCalendarUnitMinute inUnit:NSCalendarUnitHour forDate:aDate];
    return ((CGFloat)c.hour + (CGFloat)((NSUInteger)c.minute - minutesRange.location) / minutesRange.length);
}

- (NSString *)weekView:(WLCalendarWeekView *)aWeekView stringForHour:(NSUInteger)aHour;
{
    NSParameterAssert(_calendar != nil);

    NSDateComponents *hourComponents = [_calendar components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                    fromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0.0]];
    hourComponents.hour = (NSInteger)aHour;
    return [_timeFormatter stringFromDate:[_calendar dateFromComponents:hourComponents]];
}

- (NSUInteger)numberOfColumnsInWeekView:(WLCalendarWeekView *)aWeekView
{
    return self.numberOfColumns;
}

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView eventsForColumnAtIndex:(NSUInteger)anIndex
{
    return [_storage dayEventsForDate:[self dateForColumnAtIndex:anIndex]];
}

- (NSArray *)weekView:(WLCalendarWeekView *)aWeekView allDayEventsForColumnAtIndex:(NSUInteger)anIndex
{
    return [_storage allDayEventsForDate:[self dateForColumnAtIndex:anIndex]];
}


#pragma mark NSViewController

- (void)loadView
{
    self.view = [[WLCalendarWeekView alloc] init];
    [self.view prepareForHostingLayers];
    [self.view reloadDataAnimated:NO];
    [self.view scrollHour:self.hour animated:NO];
}

- (void)setView:(WLCalendarWeekView *)newView
{
    NSParameterAssert(!self.isViewLoaded);

    super.view = newView;
    self.view.dataSource = self;
}

- (WLCalendarEventsController *)representedObject
{
    return super.representedObject;
}

- (void)setRepresentedObject:(id)newRepresentedObject
{
    NSAssert([NSThread currentThread] == [NSThread mainThread], @"%@ MUST be called on the Main Thread", NSStringFromSelector(_cmd));

    if (self.representedObject)
    {
        [self.representedObject removeObservedDateRange:self.dateRangeOfColumns];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:WLCalendarEventsDidChangeNotification object:self.representedObject];
    }

    super.representedObject = newRepresentedObject;

    _storage = nil;

    if (self.representedObject)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(eventsDidChange:)
                                                     name:WLCalendarEventsDidChangeNotification
                                                   object:self.representedObject];
        [self.representedObject addObservedDateRange:self.dateRangeOfColumns];
    }

    if (self.isViewLoaded)
        [self.view reloadDataAnimated:NO];
}

@end
