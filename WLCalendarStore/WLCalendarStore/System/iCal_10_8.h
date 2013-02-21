/*
 * iCal_10_8_.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class iCal_10_8_Application, iCal_10_8_Document, iCal_10_8_Window, iCal_10_8_Calendar, iCal_10_8_DisplayAlarm, iCal_10_8_MailAlarm, iCal_10_8_SoundAlarm, iCal_10_8_OpenFileAlarm, iCal_10_8_Attendee, iCal_10_8_Todo, iCal_10_8_Event;

enum iCal_10_8_SaveOptions {
	iCal_10_8_SaveOptionsYes = 'yes ' /* Save the file. */,
	iCal_10_8_SaveOptionsNo = 'no  ' /* Do not save the file. */,
	iCal_10_8_SaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
};
typedef enum iCal_10_8_SaveOptions iCal_10_8_SaveOptions;

enum iCal_10_8_PrintingErrorHandling {
	iCal_10_8_PrintingErrorHandlingStandard = 'lwst' /* Standard PostScript error handling */,
	iCal_10_8_PrintingErrorHandlingDetailed = 'lwdt' /* print a detailed report of PostScript errors */
};
typedef enum iCal_10_8_PrintingErrorHandling iCal_10_8_PrintingErrorHandling;

enum iCal_10_8_CALParticipationStatus {
	iCal_10_8_CALParticipationStatusUnknown = 'E6na' /* No anwser yet */,
	iCal_10_8_CALParticipationStatusAccepted = 'E6ap' /* Invitation has been accepted */,
	iCal_10_8_CALParticipationStatusDeclined = 'E6dp' /* Invitation has been declined */,
	iCal_10_8_CALParticipationStatusTentative = 'E6tp' /* Invitation has been tentatively accepted */
};
typedef enum iCal_10_8_CALParticipationStatus iCal_10_8_CALParticipationStatus;

enum iCal_10_8_CALStatusType {
	iCal_10_8_CALStatusTypeCancelled = 'E4ca' /* A cancelled event */,
	iCal_10_8_CALStatusTypeConfirmed = 'E4cn' /* A confirmed event */,
	iCal_10_8_CALStatusTypeNone = 'E4no' /* An event without status */,
	iCal_10_8_CALStatusTypeTentative = 'E4te' /* A tentative event */
};
typedef enum iCal_10_8_CALStatusType iCal_10_8_CALStatusType;

enum iCal_10_8_CALPriorities {
	iCal_10_8_CALPrioritiesNoPriority = 'tdp0' /* No priority */,
	iCal_10_8_CALPrioritiesLowPriority = 'tdp9' /* Low priority */,
	iCal_10_8_CALPrioritiesMediumPriority = 'tdp5' /* Medium priority */,
	iCal_10_8_CALPrioritiesHighPriority = 'tdp1' /* High priority */
};
typedef enum iCal_10_8_CALPriorities iCal_10_8_CALPriorities;

enum iCal_10_8_CALViewTypeForScripting {
	iCal_10_8_CALViewTypeForScriptingDayView = 'E5da' /* The iCal day view */,
	iCal_10_8_CALViewTypeForScriptingWeekView = 'E5we' /* The iCal week view */,
	iCal_10_8_CALViewTypeForScriptingMonthView = 'E5mo' /* The iCal month view */
};
typedef enum iCal_10_8_CALViewTypeForScripting iCal_10_8_CALViewTypeForScripting;



/*
 * Standard Suite
 */

// The application's top-level scripting object.
@interface iCal_10_8_Application : SBApplication
+ (iCal_10_8_Application *) application;

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the active application?
@property (copy, readonly) NSString *version;  // The version number of the application.

- (id) open:(id)x;  // Open a document.
- (void) print:(id)x withProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) quitSaving:(iCal_10_8_SaveOptions)saving;  // Quit the application.
- (BOOL) exists:(id)x;  // Verify that an object exists.
- (void) createCalendarWithName:(NSString *)withName;  // Creates a new calendar (obsolete, will be removed in next release)
- (void) reloadCalendars;  // Tell the application to reload all calendar files contents
- (void) switchViewTo:(iCal_10_8_CALViewTypeForScripting)to;  // Show calendar on the given view
- (void) viewCalendarAt:(NSDate *)at;  // Show calendar on the given date
- (void) GetURL:(NSString *)x;  // Subscribe to a remote calendar through a webcal or http URL

@end

// A document.
@interface iCal_10_8_Document : SBObject

@property (copy, readonly) NSString *name;  // Its name.
@property (readonly) BOOL modified;  // Has it been modified since the last save?
@property (copy, readonly) NSURL *file;  // Its location on disk, if it has one.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// A window.
@interface iCal_10_8_Window : SBObject

@property (copy, readonly) NSString *name;  // The title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Does the window have a close button?
@property (readonly) BOOL miniaturizable;  // Does the window have a minimize button?
@property BOOL miniaturized;  // Is the window minimized right now?
@property (readonly) BOOL resizable;  // Can the window be resized?
@property BOOL visible;  // Is the window visible right now?
@property (readonly) BOOL zoomable;  // Does the window have a zoom button?
@property BOOL zoomed;  // Is the window zoomed right now?
@property (copy, readonly) iCal_10_8_Document *document;  // The document whose contents are displayed in the window.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end



/*
 * iCal
 */

// This class represents iCal.
@interface iCal_10_8_Application (ICal)

- (SBElementArray *) calendars;


@end

// This class represents a calendar.
@interface iCal_10_8_Calendar : SBObject

- (SBElementArray *) todos;
- (SBElementArray *) events;

@property (copy) NSString *name;  // This is the calendar title.
@property (copy) NSColor *color;  // The calendar color.
@property (copy, readonly) NSString *uid;  // An unique calendar key
@property (readonly) BOOL writable;  // This is the calendar title.
@property (copy) NSString *objectDescription;  // This is the calendar description.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents a message alarm.
@interface iCal_10_8_DisplayAlarm : SBObject

@property NSInteger triggerInterval;  // The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before).
@property (copy) NSDate *triggerDate;  // An absolute alarm date.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents a mail alarm.
@interface iCal_10_8_MailAlarm : SBObject

@property NSInteger triggerInterval;  // The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before).
@property (copy) NSDate *triggerDate;  // An absolute alarm date.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents a sound alarm.
@interface iCal_10_8_SoundAlarm : SBObject

@property NSInteger triggerInterval;  // The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before).
@property (copy) NSDate *triggerDate;  // An absolute alarm date.
@property (copy) NSString *soundName;  // The system sound name to be used for the alarm
@property (copy) NSString *soundFile;  // The (POSIX) path to the sound file to be used for the alarm

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents an 'open file' alarm.
@interface iCal_10_8_OpenFileAlarm : SBObject

@property NSInteger triggerInterval;  // The interval in minutes between the event and the alarm: (positive for alarm that trigger after the event date or negative for alarms that trigger before).
@property (copy) NSDate *triggerDate;  // An absolute alarm date.
@property (copy) NSString *filepath;  // The (POSIX) path to be opened by the alarm

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents a attendee.
@interface iCal_10_8_Attendee : SBObject

@property (copy, readonly) NSString *displayName;  // The first and last name of the attendee.
@property (copy, readonly) NSString *email;  // e-mail of the attendee.
@property (readonly) iCal_10_8_CALParticipationStatus participationStatus;  // The invitation status for the attendee.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents a task.
@interface iCal_10_8_Todo : SBObject

- (SBElementArray *) displayAlarms;
- (SBElementArray *) mailAlarms;
- (SBElementArray *) openFileAlarms;
- (SBElementArray *) soundAlarms;

@property (copy) NSDate *completionDate;  // The todo completion date.
@property (copy) NSDate *dueDate;  // The todo due date.
@property iCal_10_8_CALPriorities priority;  // The todo priority.
@property (readonly) NSInteger sequence;  // The todo version.
@property (copy, readonly) NSDate *stampDate;  // The todo modification date.
@property (copy) NSString *summary;  // This is the todo summary.
@property (copy) NSString *objectDescription;  // The todo notes.
@property (copy, readonly) NSString *uid;  // An unique todo key.
@property (copy) NSString *url;  // The URL associated to the todo.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

// This class represents an event.
@interface iCal_10_8_Event : SBObject

- (SBElementArray *) attendees;
- (SBElementArray *) displayAlarms;
- (SBElementArray *) mailAlarms;
- (SBElementArray *) openFileAlarms;
- (SBElementArray *) soundAlarms;

@property (copy) NSString *objectDescription;  // The events notes.
@property (copy) NSDate *startDate;  // The event start date.
@property (copy) NSDate *endDate;  // The event end date.
@property BOOL alldayEvent;  // True if the event is an calendar-week-all-day event
@property (copy) NSString *recurrence;  // The iCalendar (RFC 2445) string describing the event recurrence, if defined
@property (readonly) NSInteger sequence;  // The event version.
@property (copy) NSDate *stampDate;  // The event modification date.
@property (copy) NSArray *excludedDates;  // The exception dates.
@property iCal_10_8_CALStatusType status;  // The event status.
@property (copy) NSString *summary;  // This is the event summary.
@property (copy) NSString *location;  // This is the event location.
@property (copy, readonly) NSString *uid;  // An unique todo key.
@property (copy) NSString *url;  // The URL associated to the event.

- (void) closeSaving:(iCal_10_8_SaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) printWithProperties:(NSDictionary *)withProperties printDialog:(BOOL)printDialog;  // Print a document.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy an object.
- (void) moveTo:(SBObject *)to;  // Move an object to a new location.
- (void) show;  // Show the event or to-do in the calendar window

@end

