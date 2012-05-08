//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowController.h"


@class SS_PrefsController;

@class WLApplicationRunTimer;


@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate /*, NSMenuValidation*/>
{
    WLCalendarWindowController *calendarWindowController;

    NSStatusItem *_statusItem;
    IBOutlet NSMenu *_statusMenu;
    IBOutlet NSMenuItem *_bringToFrontMenuItem;
    IBOutlet NSMenuItem *_newEventMenuItem;
    IBOutlet NSMenuItem *_newTaskMenuItem;
    IBOutlet NSMenuItem *_showNextWeekMenuItem;
    IBOutlet NSMenuItem *_showCurrentWeekMenuItem;
    IBOutlet NSMenuItem *_showPreviousWeekMenuItem;
    IBOutlet NSMenuItem *preferencesMenuItem;
    SS_PrefsController *_preferencesController;
    NSTimer *_showCurrentWeekTimer;
    NSTimer *_autoFadeTimer;
    WLApplicationRunTimer *_applicationRunTimer;
    NSArray *_shortCuts;
}

@property (readonly) WLCalendarWindowController *calendarWindowController;

- (IBAction)bringToFrontOrSendToBack:(id)sender;

- (IBAction)showPreferences:(id)aSender;

- (IBAction)newEvent:(id)aSender;

- (IBAction)newTask:(id)aSender;

- (IBAction)showAbout:(id)aSender;

- (IBAction)showNextWeek:(id)aSender;

- (IBAction)showPreviousWeek:(id)aSender;

- (IBAction)showCurrentWeek:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

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


- (void)_scheduleShowCurrentWeekTimerIfNeeded;

- (void)_removeShowCurrentWeekTimerIfNeeded;

/*!
 @discussion    Automatically sent when _showCurrentWeekTimer fires.
 @see -_scheduleShowCurrentWeekTimerIfNeeded
 @see -_removeShowCurrentWeekTimerIfNeeded
 */
- (void)_showCurrentWeekTimerDidFire;

- (void)_scheduleAutoFadeTimerIfNeeded;

- (void)_removeAutoFadeTimerIfNeeded;

/*!
 @discussion    Automatically sent when _fadeOutTimer fires.
 */
- (void)_autoFadeTimerDidFire;

- (void)_addStatusItem;

- (void)_applicationRunTimerDidFire:(NSNotification *)aNotification;

@end
