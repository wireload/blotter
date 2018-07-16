//
//  WLCalendarWeekEventsViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 20.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLCalendarEventsController.h"
#import "WLCalendarWeekView.h"


/*!
    @brief      WLCalendarWeekEventsViewController manages appearance of the WLCalendarWeekView.

    @discussion Main-Thread only if otherwise is not specified.
 */
@interface WLCalendarWeekEventsViewController : WLViewController <WLCalendarWeekViewDataSource>
{
    NSCalendar *_calendar;
}

/*!
    @brief      Calendar used to perform calculations.

    @discussion Returned object is always a copy. Therefore changes you apply do not affect calendar.

                Defaults to nil.
 */
@property (nonatomic, copy) NSCalendar *calendar;

/*!
    Defaults to nil.
*/
@property (nonatomic, copy) NSDate *date;

/*!
    Defaults to NSWeekOfMonthCalendarUnit (NSWeekCalendarUnit on Mac OS X 10.6).
 */
@property (nonatomic, readonly) NSCalendarUnit offsetUnit;

/*!
    Defaults to 0.
*/
@property (nonatomic, readonly) NSInteger numberOfOffsetUnits;

/*!
    Defaults to NSWeekOfMonthCalendarUnit (NSWeekCalendarUnit on Mac OS X 10.6).
*/
@property (nonatomic, readonly) NSCalendarUnit alignmentUnit;

/*!
    Defaults to 1.
 */
@property (nonatomic, readonly) NSUInteger numberOfAlignmentUnits;

- (void)setCalendar:(NSCalendar *)newCalendar animated:(BOOL)isAnimated;

- (void)setDate:(NSDate *)newDate animated:(BOOL)isAnimated;

- (void)setOffsetUnit:(NSCalendarUnit)newOffsetUnit number:(NSInteger)newNumberOfUnits animated:(BOOL)isAnimated;

- (void)setAlignmentUnit:(NSCalendarUnit)newAlignmentUnit number:(NSUInteger)newNumberOfUnits animated:(BOOL)isAnimated;


@property (copy, readonly) NSDate *dateOfFirstColumn;

@property (readonly) NSUInteger numberOfColumns;

@property (copy, readonly) WLDateRange *dateRangeOfColumns;

@property (readonly) CGFloat hour;

@property (strong) WLCalendarWeekView *view;

- (NSDate *)makeDateOfFirstColumnForCalendar:(NSCalendar *)aCalendar
                                        date:(NSDate *)aDate
                                  offsetUnit:(NSCalendarUnit)anOffsetUnit
                         numberOfOffsetUnits:(NSInteger)aNumberOfOffsetUnits
                               alignmentUnit:(NSCalendarUnit)anAlignmentUnit;

- (WLDateRange *)makeDateRangeOfColumnsForCalendar:(NSCalendar *)aCalendar
                                 dateOfFirstColumn:(NSDate *)aDateOfFirstColumn
                                     alignmentUnit:(NSCalendarUnit)anAlignmentUnit
                            numberOfAlignmentUnits:(NSUInteger)aNumberOfAlignmentUnits;

- (NSUInteger)numberOfColumnsForCalendar:(NSCalendar *)aCalendar dateRangeOfColumns:(WLDateRange *)aDateRangeOfColumns;

- (CGFloat)hourForCalendar:(NSCalendar *)aCalendar date:(NSDate *)aDate;

- (NSDate *)dateForColumnAtIndex:(NSUInteger)anIndex;

/*!
    @brief  Returns index of a column for aDate.

    @param  aDate Date of the column you're looking for.

    @result Index of the column or NSNotFound if no column is shown for aDate.
 */
- (NSUInteger)indexOfColumnForDate:(NSDate *)aDate;

- (void)updateDerivativeProperties;

- (void)updateDerivativePropertiesAndMoveIfNeeded:(BOOL)isAnimated;


/*!
    @brief      Called when events of a represented object are changed.

    @param      aNotification WLCalendarEventsDidChangeNotification notification

    @discussion This is the only thread safe method.
 */
- (void)eventsDidChange:(NSNotification *)aNotification;

- (WLCalendarEventsController *)representedObject;

@end
