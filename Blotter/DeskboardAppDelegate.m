//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey+ShortcutRecorder.h>
#import "DeskboardAppDelegate.h"
#import "WLAnalytics.h"
#import "WLCalendarWindow.h"
#import "WLCalendarWindowController.h"
#import "WLApplicationRunTimer.h"
#import "WLGeneralPreferences.h"
#import "WLShortcutsPreferences.h"
#import "WLPositioningPreferences.h"
#import "WLLayoutPreferences.h"
#import "WLCalendarsPreferences.h"
#import "WLAboutPreferences.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


enum {
    ShortcutsNameIdx = 0,
    ShortcutsSelectorIdx = 1,
    ShortcutsMenuItemIdx = 2
};


// TODO: Update if the New Event/Task windows stop centering at first launch.
// Cocoa uses these strings to store frames of the New Event/Task windows in user defaults.
static NSString* const _WLNewEventWindowAutosaveName = @"NSWindow Frame NewEventWindow";

static NSString* const _WLNewTaskWindowAutosaveName = @"NSWindow Frame NewTaskWindow";

static NSString* const _WLStatusItemAutosaveName = @"net.wireload.blotter.mac.StatusItem";


NSString* const WLBlotterLogName = @"net.wireload.blotter.mac";

NSString* const WLMixpanelLogName = @"net.wireload.blotter.mac.mixpanel";


@implementation DeskboardAppDelegate
{
    WLApplicationPreferences *_preferencesController;
    WLNewEventWindowController *_newEventWindowController;
    WLNewReminderWindowController *_newReminderWindowController;

    NSStatusItem *_statusItem;
    NSTimer *_showCurrentWeekTimer;
    NSTimer *_autoFadeTimer;
    WLApplicationRunTimer *_applicationRunTimer;
    NSArray *_shortcuts;
}

+ (void)initialize
{
    if (self == [DeskboardAppDelegate class])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
        [userDefaults registerDefaults:defaults];
        // @see -[WLCalendarWindowController tasksViewFrame] for default value of TasksViewHeight.

        // Migrate preferences and set defaults.
        [userDefaults WL_migrateIfNeeded];
        [userDefaults WL_setDefaultScreenIdentifierIfNeeded];
    }
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults removeObserver:self forKeyPath:WLShowInMenuBar];
    [defaults removeObserver:self forKeyPath:WLAutoFadeKey];
    [defaults removeObserver:self forKeyPath:WLAutoFadeSecondsKey];
    [defaults removeObserver:self forKeyPath:WLShareAnalytics];
    [_shortcuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *shortcutName = obj[ShortcutsNameIdx];
        [defaults removeObserver:self forKeyPath:shortcutName];
    }];

    [[WLSmartClock defaultClock] removeObserver:self forKeyPath:@"date"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_showCurrentWeekTimer invalidate];
    [_autoFadeTimer invalidate];

    _shortcuts = nil;

    if (_statusItem && floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_12)
        [_statusItem removeObserver:self forKeyPath:NSVisibleBinding];
}


#pragma mark Properties

- (WLApplicationPreferences *)preferencesController
{
    if (_preferencesController == nil)
    {
        WLGeneralPreferences *general = [[WLGeneralPreferences alloc] initWithNibName:@"GeneralPrefPaneView" bundle:nil];
        WLShortcutsPreferences *shortcuts = [[WLShortcutsPreferences alloc] initWithNibName:@"ShortcutsPrefPaneView" bundle:nil];
        WLPositioningPreferences *positioning = [[WLPositioningPreferences alloc] initWithNibName:@"PositionPrefPaneView" bundle:nil];
        WLLayoutPreferences *layout = [[WLLayoutPreferences alloc] initWithNibName:@"LayoutPrefPaneView" bundle:nil];
        WLCalendarsPreferences *calendars = [[WLCalendarsPreferences alloc] initWithNibName:@"CalendarsPrefPaneView" bundle:nil];
        WLAboutPreferences *about = [[WLAboutPreferences alloc] initWithNibName:@"AboutPrefPaneView" bundle:nil];
        _preferencesController = [WLApplicationPreferences preferencesWithWindowNibName:@"WLApplicationPreferencesWindow"
                                                                           visualFormat:@"general,shortcuts,positioning,layout,calendars,-,about"
                                                                        representations:@{
                                                                           @"general": general,
                                                                           @"shortcuts": shortcuts,
                                                                           @"positioning": positioning,
                                                                           @"layout": layout,
                                                                           @"calendars": calendars,
                                                                           @"about": about
                                                                        }];
    }

    return _preferencesController;
}

- (WLNewEventWindowController *)newEventWindowController
{
    if (_newEventWindowController == nil)
    {
        _newEventWindowController = [[WLNewEventWindowController alloc] initWithWindowNibName:@"NewEventWindow"];
        [_newEventWindowController bind:@"calCalendars"
                               toObject:self.calendarWindowController.calendarsController
                            withKeyPath:@"calEventCalendarsToDisplay"
                                options:nil];
    }

    return _newEventWindowController;
}

- (WLNewReminderWindowController *)newReminderWindowController
{
    if (_newReminderWindowController == nil)
    {
        _newReminderWindowController = [[WLNewReminderWindowController alloc] initWithWindowNibName:@"NewTaskWindow"];
        [_newReminderWindowController bind:@"calCalendars"
                                  toObject:self.calendarWindowController.calendarsController
                               withKeyPath:@"calReminderCalendarsToDisplay"
                                   options:nil];
    }

    return _newReminderWindowController;
}


#pragma mark Methods

- (IBAction)bringToFrontOrSendToBack:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"BringToFront"];

    BOOL isStateChangeAnimated = [[NSUserDefaults standardUserDefaults] WL_animatesBringToFront];
    NSTimeInterval stateChangeDuration = 0.0;

    if (isStateChangeAnimated)
    {
        if (![[NSUserDefaults standardUserDefaults] WL_slowsAnimation])
            stateChangeDuration = 0.2;
        else
            stateChangeDuration = 2.0;
    }

    if (self.calendarWindowController.windowState == WLFinderLevelState)
    {
        [self.calendarWindowController setWindowState:WLFloatingLevelState
                                             animated:isStateChangeAnimated
                                             duration:stateChangeDuration];
        [NSApp activateIgnoringOtherApps:YES];

    }
    else
    {
        [self.calendarWindowController setWindowState:WLFinderLevelState
                                             animated:isStateChangeAnimated
                                             duration:stateChangeDuration];
        [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
    }
}

- (IBAction)showPreferences:(id)aSender
{
    [self.preferencesController showWindow:aSender];
    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showNewEvent:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"NewEvent"];

    if ((self.newEventWindowController).canCreateEvent)
    {
        [self.newEventWindowController resetDefaults:aSender];

        if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewEventWindowAutosaveName] == nil)
            [(self.newEventWindowController).window center];

        [self.newEventWindowController showWindow:aSender];
        [self _removeAutoFadeTimerIfNeeded];
        self.calendarWindowController.isFadedOut = NO;
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
        NSBeep();
}

- (IBAction)showNewReminder:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"NewReminder"];

    if ((self.newReminderWindowController).canCreateReminder)
    {
        [self.newReminderWindowController resetDefaults:aSender];

        if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewTaskWindowAutosaveName] == nil)
            [(self.newReminderWindowController).window center];

        [self.newReminderWindowController showWindow:aSender];
        [self _removeAutoFadeTimerIfNeeded];
        self.calendarWindowController.isFadedOut = NO;
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
        NSBeep();
}

- (IBAction)showAbout:(id)aSender
{
    [self.preferencesController setSelectedRepresentationIdentifier:@"about" animated:NO];
    [self showPreferences:aSender];
}

- (IBAction)showNextWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"NextWeek"];

    if ([self.calendarWindowController canShowNextWeek])
    {
        [self.calendarWindowController showNextWeek:aSender];
        if ([self.calendarWindowController isCurrentWeekShowed])
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [self _removeAutoFadeTimerIfNeeded];
            self.calendarWindowController.isFadedOut = NO;
        }
    }
    else
        NSBeep();
}

- (IBAction)showPreviousWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"PreviousWeek"];

    if ([self.calendarWindowController canShowPreviousWeek])
    {
        [self.calendarWindowController showPreviousWeek:aSender];
        if ([self.calendarWindowController isCurrentWeekShowed])
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [self _removeAutoFadeTimerIfNeeded];
            self.calendarWindowController.isFadedOut = NO;
        }
    }
    else
        NSBeep();
}

- (IBAction)showCurrentWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"CurrentWeek"];

    if ([self.calendarWindowController canShowCurrentWeek])
    {
        [self _removeShowCurrentWeekTimerIfNeeded];
        [self.calendarWindowController showCurrentWeek:aSender];
        [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
    }
    else
        NSBeep();
}

- (IBAction)showRateThisApp:(id)aSender
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_rateThisAppURL]];
    [self hideRateThisAppMenuItem];
}

- (void)toggleStatusItem
{
    if ([[NSUserDefaults standardUserDefaults] WL_showInMenuBar])
    {
        if (_statusItem)
            return;

        NSImage *statusImage = [NSImage imageNamed:@"status-bar"];
        statusImage.template = YES;

        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        _statusItem.menu = _statusMenu;
        _statusItem.button.image = statusImage;

        if (@available(macOS 10.12, *))
        {
            _statusItem.autosaveName = _WLStatusItemAutosaveName;
            _statusItem.behavior = NSStatusItemBehaviorRemovalAllowed;
            [_statusItem addObserver:self forKeyPath:NSVisibleBinding options:NSKeyValueObservingOptionNew context:NULL];
        }
    }
    else
    {
        if (!_statusItem)
            return;

        // TODO: Might make sense to use the visibility property instead of removal.
        // That requres deployment target 10.12
        [_statusItem removeObserver:self forKeyPath:NSVisibleBinding];
        [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
        _statusItem = nil;
    }
}

- (void)showRateThisAppMenuItem
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d WL_setApplicationRunTimerIsFired:YES];
    [d WL_setApplicationRunTimerElapsedSeconds:[d WL_applicationRunTimerDelay] + 1.0];
    [d WL_setShowRateThisAppInMenu:YES];

    _applicationRunTimer = nil;
}

- (void)hideRateThisAppMenuItem
{
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d WL_setApplicationRunTimerIsFired:YES];
    [d WL_setApplicationRunTimerElapsedSeconds:[d WL_applicationRunTimerDelay] + 1.0];
    [d WL_setShowRateThisAppInMenu:NO];
}

- (BOOL)isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows
{
    NSMutableArray *visibleWindows = [aVisibleWindows mutableCopy];
    [visibleWindows filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSWindow *w, NSDictionary *bindings) {
        return w.visible && ![w.className hasPrefix:@"NSStatusBarWindow"];
    }]];
    return (visibleWindows.count == 1); // If only desktop window is visible
}

- (void)scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:(NSArray *)aWindows
{
    BOOL isBlotterActive = NSApp.active;
    BOOL areThereUtilityWindows = ![self isOnlyCalendarWindowVisible:aWindows];
    BOOL isCurrentWeekShowed = [self.calendarWindowController isCurrentWeekShowed];
    if ((!isBlotterActive && !areThereUtilityWindows && isCurrentWeekShowed) ||
        (!isBlotterActive && areThereUtilityWindows && isCurrentWeekShowed) ||
        (isBlotterActive && !areThereUtilityWindows && isCurrentWeekShowed))
    {
        [self _scheduleAutoFadeTimerIfNeeded];
    }
}

- (void)deactivateAppIfAllConditionsAreMet:(NSArray *)aWindows
{
    if ([self isOnlyCalendarWindowVisible:aWindows] && self.calendarWindowController.windowState == WLFinderLevelState)
        [NSApp hide:self];
}


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Configure status bar
    [defaults addObserver:self forKeyPath:WLShowInMenuBar options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];

    // Configure shortcuts
    [NSValueTransformer setValueTransformer:[[SRKeyEquivalentTransformer alloc] init] forName:@"SRKeyEquivalentTransformer"];
    [NSValueTransformer setValueTransformer:[[SRKeyEquivalentModifierMaskTransformer alloc] init] forName:@"SRKeyEquivalentModifierMaskTransformer"];
    _shortcuts = @[
        @[@"shortcutNewEvent", @"showNewEvent:", _newEventMenuItem],
        @[@"shortcutNewTask", @"showNewReminder:", _newTaskMenuItem],
        @[@"shortcutShowNextWeek", @"showNextWeek:", _showNextWeekMenuItem],
        @[@"shortcutShowPreviousWeek", @"showPreviousWeek:", _showPreviousWeekMenuItem],
        @[@"shortcutShowCurrentWeek", @"showCurrentWeek:", _showCurrentWeekMenuItem],
        @[@"shortcutBringToFront", @"bringToFrontOrSendToBack:", _bringToFrontMenuItem]
    ];
    [_shortcuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *shortcutName = obj[ShortcutsNameIdx];
        [defaults addObserver:self forKeyPath:shortcutName options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:(void *)idx];
    }];

    // Configure windows.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    _calendarWindowController = [[WLCalendarWindowController alloc] init];
    [_calendarWindowController showWindow:self];

    // Show preferences at first start or to request share analytics consent.
    if ([defaults boolForKey:WLShowPreferencesAtStartUp] || [defaults boolForKey:WLRequestShareAnalyticsConsentAtStartup])
    {
        [self showPreferences:self];
        [defaults setBool:NO forKey:WLShowPreferencesAtStartUp];
    }

    // Configure application run timer.
    if (![defaults WL_applicationRunTimerIsFired])
    {
        _applicationRunTimer = [[WLApplicationRunTimer alloc] initWithDelayDefaultsKey:WLApplicationRunTimerDelayKey
                                                                    isFiredDefaultsKey:WLApplicationRunTimerIsFiredKey
                                                             elapsedSecondsDefaultsKey:WLApplicationRunTimerElapsedSecondsKey];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showRateThisAppMenuItem)
                                                     name:WLApplicationRunTimerDidFireNotification
                                                   object:_applicationRunTimer];
    }

    [[WLSmartClock defaultClock] addObserver:self
                                  forKeyPath:@"date"
                                     options:NSKeyValueObservingOptionNew
                                     context:NULL];

    [defaults addObserver:self
               forKeyPath:WLAutoFadeKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    [defaults addObserver:self
               forKeyPath:WLAutoFadeSecondsKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [defaults addObserver:self
               forKeyPath:WLShareAnalytics
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                  context:NULL];

    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
    [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    BOOL isStateChangeAnimated = [[NSUserDefaults standardUserDefaults] WL_animatesBringToFront];
    NSTimeInterval stateChangeDuration = 0.0;
    if (isStateChangeAnimated)
    {
        if (![[NSUserDefaults standardUserDefaults] WL_slowsAnimation])
            stateChangeDuration = 0.2;
        else
            stateChangeDuration = 2.0;
    }
    [self.calendarWindowController setWindowState:WLFinderLevelState
                                         animated:isStateChangeAnimated
                                         duration:stateChangeDuration];

    [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)anApplication hasVisibleWindows:(BOOL)aFlag
{
    if(![[NSUserDefaults standardUserDefaults] WL_showInMenuBar])
        [self showPreferences:self];

    return NO;
}


#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)aNotification
{
    NSMutableArray *visibleWindows = [NSApp.windows mutableCopy];
    NSWindow *closedWindow = aNotification.object;
    [visibleWindows removeObjectIdenticalTo:closedWindow];
    [self deactivateAppIfAllConditionsAreMet:visibleWindows];
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:visibleWindows];
}


#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)aMenu
{
    [_shortcuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // If the menu item is nil, the shortcut definition will only be 2 items long. Ignore those.
         if ([obj count] < 3)
             return;

         NSString *shortcutName = obj[ShortcutsNameIdx];
         NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:shortcutName];
         NSMenuItem *shortcutMenuItem = obj[ShortcutsMenuItemIdx];

         if (shortcut != nil)
         {
             shortcutMenuItem.keyEquivalent = [[NSValueTransformer valueTransformerForName:@"SRKeyEquivalentTransformer"] transformedValue:shortcut];
             shortcutMenuItem.keyEquivalentModifierMask = [[[NSValueTransformer valueTransformerForName:@"SRKeyEquivalentModifierMaskTransformer"] transformedValue:shortcut] unsignedIntegerValue];
         }
         else
         {
             shortcutMenuItem.keyEquivalent = @"";
             shortcutMenuItem.keyEquivalentModifierMask = 0;
         }
     }];

    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
}


#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == _newEventMenuItem)
        return (self.newEventWindowController).canCreateEvent;
    else if (aMenuItem == _newTaskMenuItem)
        return (self.newReminderWindowController).canCreateReminder;
    else if (aMenuItem == _showNextWeekMenuItem)
        return [self.calendarWindowController canShowNextWeek];
    else if (aMenuItem == _showCurrentWeekMenuItem)
        return [self.calendarWindowController canShowCurrentWeek];
    else if (aMenuItem == _showPreviousWeekMenuItem)
        return [self.calendarWindowController canShowPreviousWeek];
    else if (aMenuItem == _bringToFrontMenuItem)
    {
        if (self.calendarWindowController.windowState != WLFinderLevelState)
            [aMenuItem setTitle:NSLocalizedString(@"Send to Back", @"Send to Back menu item title")];
        else
            [aMenuItem setTitle:NSLocalizedString(@"Bring to Front", @"Bring to Front menu item title")];

        return YES;
    }
    else
        return YES;
}


#pragma mark NSAlertDelegate

- (BOOL)alertShowHelp:(NSAlert *)anAlert
{
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_privacyPolicyURL]];
    return YES;
}


#pragma mark Private

- (void)_scheduleShowCurrentWeekTimerIfNeeded
{
    [self _removeShowCurrentWeekTimerIfNeeded];
    NSInteger delay = [[NSUserDefaults standardUserDefaults] integerForKey:@"AutoShowCurrentWeekDelay"];
    if (delay > 0)
    {
        _showCurrentWeekTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                                 target:self
                                                               selector:@selector(_showCurrentWeekTimerDidFire)
                                                               userInfo:nil
                                                                repeats:NO];
    }
    else
        _showCurrentWeekTimer = nil;
}

- (void)_removeShowCurrentWeekTimerIfNeeded
{
    [_showCurrentWeekTimer invalidate];
    _showCurrentWeekTimer = nil;
}

- (void)_showCurrentWeekTimerDidFire
{
    _showCurrentWeekTimer = nil;
    [self showCurrentWeek:self];
}

- (void)_scheduleAutoFadeTimerIfNeeded
{
    [self _removeAutoFadeTimerIfNeeded];
    BOOL isAutoFadeEnabled = [[NSUserDefaults standardUserDefaults] WL_autoFadeSeconds] > 0;
    NSTimeInterval delay = [[NSUserDefaults standardUserDefaults] WL_autoFadeSeconds];
    if (isAutoFadeEnabled && delay > 0)
    {
        _autoFadeTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                          target:self
                                                        selector:@selector(_autoFadeTimerDidFire)
                                                        userInfo:nil
                                                         repeats:NO];
    }
    else
        _autoFadeTimer = nil;
}

- (void)_removeAutoFadeTimerIfNeeded
{
    [_autoFadeTimer invalidate];
    _autoFadeTimer = nil;
}

- (void)_autoFadeTimerDidFire
{
    _autoFadeTimer = nil;
    if (![[NSUserDefaults standardUserDefaults] WL_autoFades])
        return;
    self.calendarWindowController.isFadedOut = YES;
}


#pragma mark NSResponder

- (void)cancelOperation:(id)aSender
{
    if (self.calendarWindowController.windowState == WLFloatingLevelState &&
        NSApp.keyWindow == [self.calendarWindowController window])
    {
        [self bringToFrontOrSendToBack:aSender];
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath hasPrefix:@"shortcut"])
    {
        NSArray *shortcut = _shortcuts[(NSUInteger)aContext];
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];

        NSDictionary *newHotKeyDict = aChange[NSKeyValueChangeNewKey];
        if (newHotKeyDict != nil && (id)newHotKeyDict != [NSNull null])
        {
            PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath
                                                        keyCombo:newHotKeyDict
                                                          target:self
                                                          action:NSSelectorFromString(shortcut[ShortcutsSelectorIdx])];
            [hotKeyCenter registerHotKey:newHotKey];
        }
    }
    else if ([aKeyPath isEqualToString:WLShowInMenuBar])
        [self toggleStatusItem];
    else if ([aKeyPath isEqualToString:@"date"])
    {
        [_applicationRunTimer tick];
        [WLAnalytics.sharedAnalytics reportDailyToMixpanelIfNeeded];
    }
    else if ([aKeyPath isEqualToString:WLAutoFadeKey] || [aKeyPath isEqualToString:WLAutoFadeSecondsKey])
    {
        if ([[NSUserDefaults standardUserDefaults] WL_autoFades])
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        else
        {
            [self _removeAutoFadeTimerIfNeeded];
            self.calendarWindowController.isFadedOut = NO;
        }
    }
    else if ([aKeyPath isEqualToString:NSVisibleBinding])
        [[NSUserDefaults standardUserDefaults] setValue:aChange[NSKeyValueChangeNewKey] forKeyPath:WLShowInMenuBar];
    else if ([aKeyPath isEqualToString:WLShareAnalytics])
    {
        [WLAnalytics.sharedAnalytics reportLaunchedToMixpanelIfNeeded];
        [WLAnalytics.sharedAnalytics reportDailyToMixpanelIfNeeded];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:aObject change:aChange context:aContext];
}

@end
