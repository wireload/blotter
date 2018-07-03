//
//  WLNewReminderWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLCalendarStore/WLCalendarStore.h>


@class WLGlassHudTextView;


/*!
    @brief  Represents dialog to add new reminders.
*/
@interface WLNewReminderWindowController : NSWindowController
{
    IBOutlet WLGlassHudTextView *_titleView;
    IBOutlet NSButton *_createButton;
}

/*!
    @brief  Determines whether reminder has due date.
*/
@property BOOL isDueDate;

/*!
    @brief  If isDueDate returns YES, determines due date of reminder.
*/
@property (copy) NSDate *dueDate;

/*!
    @brief  Title of reminder.
*/
@property (copy) NSString *title;

/*!
    @brief  Priority of reminder.
    
    @see    WLCalPriority.
*/
@property WLCalPriority priority;

/*!
    @brief  List of possible cal calendars.
*/
@property (nonatomic, copy) NSArray *calCalendars;

/*!
    @brief  Resents isDueDate, dueDate, title and priority to default values.
*/
- (IBAction)resetDefaults:(id)aSender;

/*!
    @brief      Creates new event with set properties.
 
    @discussion If event cannot be created, beeps and optionally shows error via -[NSApp presentError:].
*/
- (IBAction)create:(id)aSender;

@end


@interface WLNewReminderWindowController (Appearance)

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
    @brief      Determines whether reminder can be created.
 
    @discussion Reminder can be created if there are editable calendars.
*/
@property (nonatomic, readonly) BOOL canCreateReminder;

@end
