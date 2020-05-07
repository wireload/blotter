//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowController.h"
#import "WLPreferencesWindowController.h"
#import "WLNewEventWindowController.h"
#import "WLNewReminderWindowController.h"


extern NSString* const WLBlotterLogName;

extern NSString* const WLMixpanelLogName;


extern NSStoryboardSceneIdentifier const WLPreferencesWindowIdentifier;


NS_ASSUME_NONNULL_BEGIN

@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate, NSMenuItemValidation>
{
    IBOutlet NSMenu *_statusMenu;
    IBOutlet NSMenuItem *_bringToFrontMenuItem;
    IBOutlet NSMenuItem *_newEventMenuItem;
    IBOutlet NSMenuItem *_newTaskMenuItem;
    IBOutlet NSMenuItem *_showNextWeekMenuItem;
    IBOutlet NSMenuItem *_showCurrentWeekMenuItem;
    IBOutlet NSMenuItem *_showPreviousWeekMenuItem;
    IBOutlet NSMenuItem *_preferencesMenuItem;
}

@property (readonly) NSStoryboard *storyboard;

@property (readonly) WLCalendarWindowController *calendarWindowController;

@property (nonatomic, readonly) WLPreferencesWindowController *preferencesWindowController;

@property (nonatomic, readonly) WLNewEventWindowController *newEventWindowController;

@property (nonatomic, readonly) WLNewReminderWindowController *newReminderWindowController;

- (IBAction)bringToFrontOrSendToBack:(id)sender;

- (IBAction)showPreferences:(id)aSender;

- (IBAction)showNewEvent:(id)aSender;

- (IBAction)showNewReminder:(id)aSender;

- (IBAction)showAbout:(id)aSender;

- (IBAction)showNextWeek:(id)aSender;

- (IBAction)showPreviousWeek:(id)aSender;

- (IBAction)showCurrentWeek:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

/*!
    @brief  Toggles visibility of status item according to settings in user defaults.
 */
- (void)toggleStatusItem;

/*!
    @brief  Makes the Rate This App menu item visible.
 */
- (void)showRateThisAppMenuItem;

/*!
    @brief  Makes the Rate This App menu item hidden.
 */
- (void)hideRateThisAppMenuItem;

/*!
    @abstract Determines whether only calendar window is visible.
 */
- (BOOL)isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows;

/*!
    @abstract Autohides the calendar window if all conditions are met.

    @see https://tracker.wireload.net/projects/blotter/wiki/Autohide
 */
- (void)scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:(NSArray *)aWindows;

/*!
    @abstract Deactivates application by sending -hide: to NSApp.
 */
- (void)deactivateAppIfAllConditionsAreMet:(NSArray *)aWindows;

/*!
 Called when the preferences window is closed to release the associated resources.
 */
- (void)preferencesWindowDidClose:(NSNotification *)aNotification;


- (void)_scheduleShowCurrentWeekTimerIfNeeded;

- (void)_removeShowCurrentWeekTimerIfNeeded;

- (void)_showCurrentWeekTimerDidFire;


- (void)_scheduleAutoFadeTimerIfNeeded;

- (void)_removeAutoFadeTimerIfNeeded;

- (void)_autoFadeTimerDidFire;

@end


#define WLAppDelegate ((DeskboardAppDelegate *)NSApp.delegate)

NS_ASSUME_NONNULL_END
