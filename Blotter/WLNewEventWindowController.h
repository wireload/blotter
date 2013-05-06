//
//  WLNewEventWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLGlassHudDatePicker.h"


@class WLGlassHudTextView;


@interface WLNewEventWindowController : NSWindowController <NSWindowDelegate, WLGlassHudDatePickerCellDelegate>
{
    IBOutlet WLGlassHudTextView *_titleView;
    IBOutlet WLGlassHudTextView *_locationView;
    IBOutlet NSView *_locationViewContainer;
    IBOutlet WLGlassHudDatePicker *_startDatePicker;
    IBOutlet WLGlassHudDatePicker *_endDatePicker;
    IBOutlet NSButton *_createButton;
}

/*!
    @brief  Title of the event.
*/
@property (copy) NSString *title;

/*!
    @brief  Location of the event.
*/
@property (copy) NSString *location;

/*!
    @brief  Determines whether event is all day.
*/
@property BOOL isAllDay;

/*!
    @brief  Start date of the event.
*/
@property (copy) NSDate *startDate;

/*!
    @brief  End date of the event.
 */
@property (copy) NSDate *endDate;

/*!
    @brief  List of possible CalCalendars.
*/
@property (copy) NSArray *calCalendars;

- (IBAction)resetDefaults:(id)aSender;

- (IBAction)create:(id)aSender;

@end


@interface WLNewEventWindowController (Appearance)

/*!
    @brief      List of editable calendars
 
    @discussion Order of calendars matches order in calCalendars.

    @see        calCalendars
*/
@property (nonatomic, readonly) NSArray *editableCalCalendars;

/*!
    @brief      Index of the selected editable cal calendar.
 
    @discussion Remebers last selected calendar across launches.
 */
@property (nonatomic) NSUInteger selectedCalCalendarIndex;

/*!
    @brief      Determines whether event can be created.
 
    @discussion Event can be created if there are editable calendars.
 */
@property (nonatomic, readonly) BOOL canCreateEvent;

/*!
    @brief      Determines displayed date picker elements.
 
    @discussion Does not display hour and minute pickers for all day event.
*/
@property (nonatomic, readonly) NSDatePickerElementFlags datePickerElements;

@end
