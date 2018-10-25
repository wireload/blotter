//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowController.h"
#import "WLApplicationPreferences.h"
#import "WLNewEventWindowController.h"
#import "WLNewReminderWindowController.h"
#import "MixpanelProtocol.h"


extern NSString* const WLBlotterLogName;

extern NSString* const WLMixpanelLogName;


NS_ASSUME_NONNULL_BEGIN

@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate /*, NSMenuValidation*/>
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

@property (readonly) WLCalendarWindowController *calendarWindowController;

@property (nonatomic, readonly) WLApplicationPreferences *preferencesController;

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

- (NSXPCConnection *)_makeReportConnection;

- (NSDictionary *)_makeReportAppProperties;

/*!
    @brief Report the Launched event to Mixpanel.

    @discussion Reports only once per application lifetime and only if user gave consent.

    @see WLShareAnalytics
 */
- (void)_reportLaunchedToMixpanelIfNeeded;

/*!
    @brief Report the Daily event to Mixpanel.

    @discussion Reports daily (if system allows) only if user gave consent.

    @see WLShareAnalytics
 */
- (void)_reportDailyToMixpanelIfNeeded;


- (void)_scheduleShowCurrentWeekTimerIfNeeded;

- (void)_removeShowCurrentWeekTimerIfNeeded;

- (void)_showCurrentWeekTimerDidFire;


- (void)_scheduleAutoFadeTimerIfNeeded;

- (void)_removeAutoFadeTimerIfNeeded;

- (void)_autoFadeTimerDidFire;


- (NSDictionary *)_parseReceipt;

@end

NS_ASSUME_NONNULL_END
