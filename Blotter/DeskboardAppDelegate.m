//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

#import "DeskboardAppDelegate.h"
#import "WLAnalytics.h"
#import "WLApplicationRunTimer.h"
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLLogNames.h"


// TODO: Update if the New Event/Task windows stop centering at first launch.
// Cocoa uses these strings to store frames of the New Event/Task windows in user defaults.
static NSString* const _WLNewEventWindowAutosaveName = @"NSWindow Frame NewEventWindow";

static NSString* const _WLNewTaskWindowAutosaveName = @"NSWindow Frame NewTaskWindow";

static NSString* const _WLStatusItemAutosaveName = @"net.wireload.blotter.mac.StatusItem";


const NSStoryboardSceneIdentifier WLCalendarWindowIdentifier = @"WLCalendarWindow";

const NSStoryboardSceneIdentifier WLPreferencesWindowIdentifier = @"WLPreferencesWindow";


@implementation DeskboardAppDelegate
{
    IBOutlet NSMenu *_statusMenu;
    IBOutlet NSMenuItem *_bringToFrontMenuItem;
    IBOutlet NSMenuItem *_newEventMenuItem;
    IBOutlet NSMenuItem *_newTaskMenuItem;
    IBOutlet NSMenuItem *_showNextWeekMenuItem;
    IBOutlet NSMenuItem *_showCurrentWeekMenuItem;
    IBOutlet NSMenuItem *_showPreviousWeekMenuItem;
    IBOutlet NSMenuItem *_preferencesMenuItem;

    WLCalendarWindowController *__calendarWindowController;
    WLPreferencesWindowController *_preferencesWindowController;
    WLNewEventWindowController *_newEventWindowController;
    WLNewReminderWindowController *_newReminderWindowController;

    NSStatusItem *_statusItem;
    NSTimer *_showCurrentWeekTimer;
    NSTimer *_autoFadeTimer;
    WLApplicationRunTimer *_applicationRunTimer;

    NSDictionary<NSUserInterfaceItemIdentifier, SRShortcutAction *> *_shortcutActions;
}

+ (void)initialize
{
    if (self == DeskboardAppDelegate.class)
    {
        // Migrate preferences and set defaults.
        __auto_type defaults = NSUserDefaults.standardUserDefaults;
        [defaults WL_registerDefaults];
        [defaults WL_migrateIfNeeded];
        [defaults WL_validateAndFixIfNeeded];
    }
}

- (void)dealloc
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObserver:self forKeyPath:WLShowInMenuBar];
    [defaults removeObserver:self forKeyPath:WLAutoFadeKey];
    [defaults removeObserver:self forKeyPath:WLAutoFadeSecondsKey];
    [defaults removeObserver:self forKeyPath:WLShareAnalytics];
    _shortcutActions = nil;

    [WLSmartClock.defaultClock removeObserver:self forKeyPath:@"date"];

    [NSNotificationCenter.defaultCenter removeObserver:self];

    [_showCurrentWeekTimer invalidate];
    [_autoFadeTimer invalidate];

    if (@available(macOS 10.12, *))
    {
        if (_statusItem)
            [_statusItem removeObserver:self forKeyPath:NSVisibleBinding];
    }
}


#pragma mark Properties

- (NSStoryboard *)storyboard
{
    if (@available(macOS 10.13, *))
    {
        return NSStoryboard.mainStoryboard;
    }
    else
    {
        static NSStoryboard *MainStoryboard;
        static dispatch_once_t OnceToken;
        dispatch_once(&OnceToken, ^{
            NSBundle *mainBundle = NSBundle.mainBundle;
            NSStoryboardName mainStoryboardName = mainBundle.infoDictionary[@"NSMainStoryboardFile"];
            MainStoryboard = [NSStoryboard storyboardWithName:mainStoryboardName bundle:mainBundle];
        });

        return MainStoryboard;
    }
}

- (WLCalendarWindowController *)calendarWindowController
{
    if (!__calendarWindowController)
        __calendarWindowController = [WLCalendarWindowController new];

    return __calendarWindowController;
}

- (WLPreferencesWindowController *)preferencesWindowController
{
    if (!_preferencesWindowController)
    {
        _preferencesWindowController = [self.storyboard instantiateControllerWithIdentifier:WLPreferencesWindowIdentifier];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(preferencesWindowDidClose:)
                                                   name:NSWindowWillCloseNotification
                                                 object:_preferencesWindowController.window];
    }

    return _preferencesWindowController;
}

- (WLNewEventWindowController *)newEventWindowController
{
    if (_newEventWindowController == nil)
    {
        _newEventWindowController = [[WLNewEventWindowController alloc] initWithWindowNibName:@"NewEventWindow"];
        [_newEventWindowController bind:@"calCalendars"
                               toObject:self.calendarsController
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
                                  toObject:self.calendarsController
                               withKeyPath:@"calReminderCalendarsToDisplay"
                                   options:nil];
    }

    return _newReminderWindowController;
}


#pragma mark Methods

- (IBAction)bringToFrontOrSendToBack:(id)aSender
{
    if (self.calendarWindowController.windowState <= WLCalendarWindowStateInactive)
    {
        self.calendarWindowController.windowState = WLCalendarWindowStateActive;
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
    {
        self.calendarWindowController.windowState = WLCalendarWindowStateInactive;
        [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
    }
}

- (IBAction)showPreferences:(id)aSender
{
    [self.preferencesWindowController showWindow:aSender];
    [self fadeIn];
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
        [self fadeIn];
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
        [self fadeIn];
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
        NSBeep();
}

- (IBAction)showAbout:(id)aSender
{
    self.preferencesWindowController.contentViewController.selectedPreferencesIdentifier = WLAboutPreferencesIdentifier;
    [self showPreferences:aSender];
}

- (IBAction)showNextWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"NextWeek"];

    __auto_type calendarViewController = self.calendarWindowController.calendarViewController;

    if (calendarViewController.canShowNextWeek)
    {
        [calendarViewController showNextWeek:aSender];

        if (calendarViewController.isCurrentWeekShown)
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [self fadeIn];
        }
    }
    else
        NSBeep();
}

- (IBAction)showPreviousWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"PreviousWeek"];

    __auto_type calendarViewController = self.calendarWindowController.calendarViewController;

    if (calendarViewController.canShowPreviousWeek)
    {
        [calendarViewController showPreviousWeek:aSender];

        if (calendarViewController.isCurrentWeekShown)
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [self fadeIn];
        }
    }
    else
        NSBeep();
}

- (IBAction)showCurrentWeek:(id)aSender
{
    [WLAnalytics.sharedAnalytics reportAction:@"CurrentWeek"];

    __auto_type calendarViewController = self.calendarWindowController.calendarViewController;

    if (calendarViewController.canShowCurrentWeek)
    {
        [self _removeShowCurrentWeekTimerIfNeeded];
        [calendarViewController showCurrentWeek:aSender];
        [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
    }
    else
        NSBeep();
}

- (IBAction)showRateThisApp:(id)aSender
{
    [NSWorkspace.sharedWorkspace openURL:NSUserDefaults.standardUserDefaults.WL_rateThisAppURL];
    [self hideRateThisAppMenuItem];
}

- (void)toggleStatusItem
{
    if (NSUserDefaults.standardUserDefaults.WL_showInMenuBar)
    {
        if (_statusItem)
            return;

        NSImage *statusImage = [NSImage imageNamed:@"status-bar"];
        statusImage.template = YES;

        _statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
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

        [_statusItem removeObserver:self forKeyPath:NSVisibleBinding];
        [NSStatusBar.systemStatusBar removeStatusItem:_statusItem];
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

- (void)fadeIn
{
    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
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
    BOOL isCurrentWeekShown = self.calendarWindowController.calendarViewController.isCurrentWeekShown;

    if ((!isBlotterActive && !areThereUtilityWindows && isCurrentWeekShown) ||
        (!isBlotterActive && areThereUtilityWindows && isCurrentWeekShown) ||
        (isBlotterActive && !areThereUtilityWindows && isCurrentWeekShown))
    {
        [self _scheduleAutoFadeTimerIfNeeded];
    }
}

- (void)deactivateAppIfAllConditionsAreMet:(NSArray *)aWindows
{
    if ([self isOnlyCalendarWindowVisible:aWindows] && self.calendarWindowController.windowState <= WLCalendarWindowStateInactive)
        [NSApp hide:self];
}

- (void)preferencesWindowDidClose:(NSNotification *)aNotification
{
    _preferencesWindowController = nil;
}

#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#ifdef DEBUG
    [NSAnimationContext WL_enableAnimationTracking];
#endif

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;

    [self willChangeValueForKey:@"calendarsController"];
    [self willChangeValueForKey:@"calendarEventsController"];
    [self willChangeValueForKey:@"calendarRemindersController"];
    NSArray *calStores = @[[WLCalendarStore systemStore]]; // TODO: should be configurable
    _calendarsController = [[WLCalendarsController alloc] initWithCalStores:calStores autosaveKeyPath:WLCalendarsKey];
    _calendarEventsController = [[WLCalendarEventsController alloc] initWithCalStores:calStores];
    _calendarRemindersController = [[WLCalendarRemindersController alloc] initWithCalStores:calStores];
    [self didChangeValueForKey:@"calendarRemindersController"];
    [self didChangeValueForKey:@"calendarEventsController"];
    [self didChangeValueForKey:@"calendarsController"];

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_calendarsToDisplayDidChange:)
                                               name:WLCalCalendarsToDisplayDidChangeNotification
                                             object:_calendarsController];
    [self _calendarsToDisplayDidChange:nil];

    // Configure status bar
    [defaults addObserver:self
               forKeyPath:WLShowInMenuBar
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                  context:NULL];

    // Configure shortcuts
    [NSValueTransformer setValueTransformer:[[SRKeyEquivalentTransformer alloc] init]
                                    forName:@"SRKeyEquivalentTransformer"];
    [NSValueTransformer setValueTransformer:[[SRKeyEquivalentModifierMaskTransformer alloc] init]
                                    forName:@"SRKeyEquivalentModifierMaskTransformer"];

    NSMutableDictionary *actions = [NSMutableDictionary new];
    __auto_type RegisterShortcut = ^(NSString *aKeyPath, NSMenuItem *aMenuItem) {
        SRShortcutAction *action = [SRShortcutAction shortcutActionWithKeyPath:aKeyPath
                                                                      ofObject:defaults
                                                                 actionHandler:^BOOL(SRShortcutAction *anAction)
        {
            NSMenu *menu = aMenuItem.menu;
            NSInteger i = [menu indexOfItem:aMenuItem];
            NSAssert(i != -1, @"Item must be added to the menu");
            [menu performActionForItemAtIndex:i];
            return YES;
        }];

        [SRGlobalShortcutMonitor.sharedMonitor addAction:action forKeyEvent:SRKeyEventTypeDown];
        actions[aMenuItem.identifier] = action;
    };

    RegisterShortcut(@"shortcutNewEvent", _newEventMenuItem);
    RegisterShortcut(@"shortcutNewTask", _newTaskMenuItem);
    RegisterShortcut(@"shortcutShowNextWeek", _showNextWeekMenuItem);
    RegisterShortcut(@"shortcutShowPreviousWeek", _showPreviousWeekMenuItem);
    RegisterShortcut(@"shortcutShowCurrentWeek", _showCurrentWeekMenuItem);
    RegisterShortcut(@"shortcutBringToFront", _bringToFrontMenuItem);
    _shortcutActions = [actions copy];

    // Configure windows.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(windowWillClose:)
                                               name:NSWindowWillCloseNotification
                                             object:nil];
    [self.calendarWindowController showWindow:self];

    // Show preferences at first start or to request share analytics consent.
    if (defaults.WL_showPreferencesAtStartup || defaults.WL_requestShareAnalyticsConsentAtStartup)
    {
        [self showPreferences:self];
        defaults.WL_showPreferencesAtStartup = NO;
    }

    // Configure application run timer.
    if (![defaults WL_applicationRunTimerIsFired])
    {
        _applicationRunTimer = [[WLApplicationRunTimer alloc] initWithDelayDefaultsKey:WLApplicationRunTimerDelayKey
                                                                    isFiredDefaultsKey:WLApplicationRunTimerIsFiredKey
                                                             elapsedSecondsDefaultsKey:WLApplicationRunTimerElapsedSecondsKey];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(showRateThisAppMenuItem)
                                                   name:WLApplicationRunTimerDidFireNotification
                                                 object:_applicationRunTimer];
    }

    [WLSmartClock.defaultClock addObserver:self
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
    [self fadeIn];
    [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    self.calendarWindowController.windowState = WLCalendarWindowStateInactive;
    [self deactivateAppIfAllConditionsAreMet:NSApp.windows];
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)anApplication hasVisibleWindows:(BOOL)aFlag
{
    if(!NSUserDefaults.standardUserDefaults.WL_showInMenuBar)
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
    __auto_type UpdateKeyEquivalent = ^(NSMenuItem *anItem) {
        SRShortcut *shortcut = self->_shortcutActions[anItem.identifier].shortcut;

        if (shortcut != nil)
        {
            anItem.keyEquivalent = [SRKeyEquivalentTransformer.sharedTransformer transformedValue:shortcut];
            anItem.keyEquivalentModifierMask = [[SRKeyEquivalentModifierMaskTransformer.sharedTransformer transformedValue:shortcut] unsignedIntegerValue];
        }
        else
        {
            anItem.keyEquivalent = @"";
            anItem.keyEquivalentModifierMask = 0;
        }
    };

    UpdateKeyEquivalent(_newEventMenuItem);
    UpdateKeyEquivalent(_newTaskMenuItem);
    UpdateKeyEquivalent(_showNextWeekMenuItem);
    UpdateKeyEquivalent(_showCurrentWeekMenuItem);
    UpdateKeyEquivalent(_showPreviousWeekMenuItem);
    UpdateKeyEquivalent(_bringToFrontMenuItem);

    [self fadeIn];
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
}


#pragma mark NSMenuItemValidation

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    __auto_type calendarViewController = self.calendarWindowController.calendarViewController;

    if (aMenuItem == _newEventMenuItem)
        return self.newEventWindowController.canCreateEvent;
    else if (aMenuItem == _newTaskMenuItem)
        return self.newReminderWindowController.canCreateReminder;
    else if (aMenuItem == _showNextWeekMenuItem)
        return calendarViewController.canShowNextWeek;
    else if (aMenuItem == _showCurrentWeekMenuItem)
        return calendarViewController.canShowCurrentWeek;
    else if (aMenuItem == _showPreviousWeekMenuItem)
        return calendarViewController.canShowPreviousWeek;
    else if (aMenuItem == _bringToFrontMenuItem)
    {
        if (self.calendarWindowController.windowState == WLCalendarWindowStateActive)
            aMenuItem.title = NSLocalizedString(@"Send to Back", @"Send to Back menu item title");
        else
            aMenuItem.title = NSLocalizedString(@"Bring to Front", @"Bring to Front menu item title");

        return YES;
    }
    else
        return YES;
}


#pragma mark Private

- (void)_scheduleShowCurrentWeekTimerIfNeeded
{
    [self _removeShowCurrentWeekTimerIfNeeded];
    NSInteger delay = [NSUserDefaults.standardUserDefaults integerForKey:@"AutoShowCurrentWeekDelay"];

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
    BOOL isAutoFadeEnabled = NSUserDefaults.standardUserDefaults.WL_autoFadeSeconds > 0;
    NSTimeInterval delay = NSUserDefaults.standardUserDefaults.WL_autoFadeSeconds;

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

    if (!NSUserDefaults.standardUserDefaults.WL_autoFades)
        return;

    self.calendarWindowController.isFadedOut = YES;
}

- (void)_calendarsToDisplayDidChange:(NSNotification *)aNotification
{
    [NSProcessInfo.processInfo disableSuddenTermination];

    __auto_type log = [WLLog logForName:WLLogNameBlotterCalendarData];
    NSArray *stores = aNotification ? aNotification.userInfo[WLChangedCalStoresKey] : _calendarsController.calStores;

    for (NSObject<WLCalStore> *s in stores)
    {
        NSArray *reminderCalendars = [[self.calendarsController calReminderCalendarsToDisplayForStore:s] valueForKey:@"calendarIdentifier"];
        [log logDebugWithMessenger:^{
            return [NSString stringWithFormat:@"Observed Reminder Calendars: %@", reminderCalendars];
        }];
        [self.calendarRemindersController setObservedCalendarIdentifiers:[NSSet setWithArray:reminderCalendars] forStore:s];

        NSArray *eventCalendars = [[self.calendarsController calEventCalendarsToDisplayForStore:s] valueForKey:@"calendarIdentifier"];
        [log logDebugWithMessenger:^{
            return [NSString stringWithFormat:@"Observed Event Calendars: %@", eventCalendars];
        }];
        [self.calendarEventsController setObservedCalendarIdentifiers:[NSSet setWithArray:eventCalendars] forStore:s];
    }

    [NSProcessInfo.processInfo enableSuddenTermination];
}


#pragma mark NSResponder

- (void)cancelOperation:(id)aSender
{
    __auto_type calendarWindowController = self.calendarWindowController;

    if (calendarWindowController.windowState <= WLCalendarWindowStateInactive && NSApp.keyWindow == calendarWindowController.window)
    {
        [self bringToFrontOrSendToBack:aSender];
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:WLShowInMenuBar])
        [self toggleStatusItem];
    else if ([aKeyPath isEqualToString:@"date"])
    {
        [_applicationRunTimer tick];
        [WLAnalytics.sharedAnalytics reportDailyToMixpanelIfNeeded];
    }
    else if ([aKeyPath isEqualToString:WLAutoFadeKey] || [aKeyPath isEqualToString:WLAutoFadeSecondsKey])
    {
        if (NSUserDefaults.standardUserDefaults.WL_autoFades)
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:NSApp.windows];
        else
            [self fadeIn];
    }
    else if ([aKeyPath isEqualToString:NSVisibleBinding])
        NSUserDefaults.standardUserDefaults.WL_showInMenuBar = [aChange[NSKeyValueChangeNewKey] boolValue];
    else if ([aKeyPath isEqualToString:WLShareAnalytics])
    {
        [WLAnalytics.sharedAnalytics reportLaunchedToMixpanelIfNeeded];
        [WLAnalytics.sharedAnalytics reportDailyToMixpanelIfNeeded];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:aObject change:aChange context:aContext];
}

@end
