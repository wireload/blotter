//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import <PTHotKey/PTHotKeyCenter.h>
#import <PTHotKey/PTHotKey+ShortcutRecorder.h>
#import "DeskboardAppDelegate.h"
#import "WLNewEventWindowController.h"
#import "WLNewTaskWindowController.h"
#import "WLCalendarWindow.h"
#import "WLCalendarWindowController.h"
#import "WLApplicationRunTimer.h"
#import "WLGeneralPreferences.h"
#import "WLShortcutsPreferences.h"
#import "WLPositioningPreferences.h"
#import "WLLayoutPreferences.h"
#import "WLCalendarsPreferences.h"
#import "WLAboutPreferences.h"


enum {
    ShortcutsNameIdx = 0,
    ShortcutsSelectorIdx = 1,
    ShortcutsMenuItemIdx = 2
};


// TODO: Update if the New Event/Task windows stop centering at first launch.
// Cocoa uses these strings to store frames of the New Event/Task windows in user defaults.
static NSString* const _WLNewEventWindowAutosaveName = @"NSWindow Frame NewEventWindow";

static NSString* const _WLNewTaskWindowAutosaveName = @"NSWindow Frame NewTaskWindow";


@implementation DeskboardAppDelegate
{
    IKApplicationPreferences *  _preferencesController;
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
        // Migrate preferences and set defaults.
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults WL_migrateIfNeeded];
        [userDefaults WL_setDefaultScreenIdentifierIfNeeded];
        NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
        [userDefaults registerDefaults:defaults];
        // @see -[WLCalendarWindowController tasksViewFrame] for default value of TasksViewHeight.
        [WLCalendarController synchronizeCalendarInUserDefaultsWithCalCalendars];
    }
}

- (void)dealloc
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults removeObserver:self forKeyPath:WLShowInMenuBar];
    [defaults removeObserver:self forKeyPath:WLAutoFadeKey];
    [defaults removeObserver:self forKeyPath:WLAutoFadeSecondsKey];
    [_shortcuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *shortcutName = obj[ShortcutsNameIdx];
        [defaults removeObserver:self forKeyPath:shortcutName];
    }];

    if (_applicationRunTimer != nil)
        [[WLCalendarController sharedController] removeObserver:self forKeyPath:@"date"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_showCurrentWeekTimer invalidate];
    [_autoFadeTimer invalidate];

    _shortcuts = nil;
}


#pragma mark Properties

- (IKApplicationPreferences *)preferencesController
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


#pragma mark Methods

- (IBAction)bringToFrontOrSendToBack:(id)aSender
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

    if (self.calendarWindowController.windowState == WLFinderLevelState)
    {
        [self.calendarWindowController setWindowState:WLFloatingLevelState
                                             animated:isStateChangeAnimated
                                             duration:stateChangeDuration];
        [NSApp activateIgnoringOtherApps:YES];

        if ([self isOnlyCalendarWindowVisible:[NSApp windows]])
            [[self.calendarWindowController window] makeKeyWindow];
    }
    else
    {
        [self.calendarWindowController setWindowState:WLFinderLevelState
                                             animated:isStateChangeAnimated
                                             duration:stateChangeDuration];
        [self deactivateAppIfAllConditionsAreMet:[NSApp windows]];
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
    WLNewEventWindowController *controller = [WLNewEventWindowController sharedWindowController];
    if ([controller canCreateEvent])
    {
        [controller setDefaults:aSender];

        if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewEventWindowAutosaveName] == nil)
            [[controller window] center];

        [controller showWindow:aSender];
        [self _removeAutoFadeTimerIfNeeded];
        self.calendarWindowController.isFadedOut = NO;
        [NSApp activateIgnoringOtherApps:YES];
    }
    else
        NSBeep();
}

- (IBAction)showNewTask:(id)aSender
{
    WLNewTaskWindowController *controller = [WLNewTaskWindowController sharedWindowController];
    if ([controller canCreateTask])
    {
        [controller setDefaults:aSender];

        if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewTaskWindowAutosaveName] == nil)
            [[controller window] center];

        [controller showWindow:aSender];
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
    if ([self.calendarWindowController canShowNextWeek])
    {
        [self.calendarWindowController showNextWeek:aSender];
        if ([self.calendarWindowController isCurrentWeekShowed])
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
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
    if ([self.calendarWindowController canShowPreviousWeek])
    {
        [self.calendarWindowController showPreviousWeek:aSender];
        if ([self.calendarWindowController isCurrentWeekShowed])
        {
            [self _removeShowCurrentWeekTimerIfNeeded];
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
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
    if ([self.calendarWindowController canShowCurrentWeek])
    {
        [self _removeShowCurrentWeekTimerIfNeeded];
        [self.calendarWindowController showCurrentWeek:aSender];
        [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
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

        _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
        [_statusItem setHighlightMode:YES];
        [_statusItem setMenu:_statusMenu];

        NSImage *statusImage = [NSImage imageNamed:@"blotter-status-bar"];
        NSImage *statusHighlightImage = [NSImage imageNamed:@"blotter-status-bar-active"];
        [_statusItem setImage:statusImage];
        [_statusItem setAlternateImage:statusHighlightImage];
    }
    else
    {
        if (!_statusItem)
            return;

        [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
        _statusItem = nil;
    }
}

- (void)showRateThisAppMenuItem
{
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:YES];
    _applicationRunTimer = nil;
    [[WLCalendarController sharedController] removeObserver:self forKeyPath:@"date"];
}

- (void)hideRateThisAppMenuItem
{
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:NO];
}

- (BOOL)isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows
{
    NSMutableArray *visibleWindows = [aVisibleWindows mutableCopy];
    [visibleWindows filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSWindow *w, NSDictionary *bindings) {
        return [w isVisible] && ![[w className] hasPrefix:@"NSStatusBarWindow"];
    }]];
    return ([visibleWindows count] == 1); // If only desktop window is visible
}

- (void)scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:(NSArray *)aWindows
{
    BOOL isBlotterActive = [NSApp isActive];
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
                   @[@"shortcutNewEvent", @"newEvent:", _newEventMenuItem],
                   @[@"shortcutNewTask", @"newTask:", _newTaskMenuItem],
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

    // Show preferences at first start.
    if ([defaults boolForKey:@"ShowPreferencesAtStartUp"])
    {
        [self showPreferences:self];
        [defaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }

    // Configure application run timer.
    if (![defaults WL_applicationRunTimerIsFired])
    {
        _applicationRunTimer = [[WLApplicationRunTimer alloc] initWithDelayDefaultsKey:WLApplicationRunTimerDelayKey
                                                                    isFiredDefaultsKey:WLApplicationRunTimerIsFiredKey
                                                             elapsedSecondsDefaultsKey:WLApplicationRunTimerElapsedSecondsKey];
        // Bind tick to changes of WLCalendarController's date. So we can avoid using additional timer.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showRateThisAppMenuItem)
                                                     name:WLApplicationRunTimerDidFireNotification
                                                   object:_applicationRunTimer];
        [[WLCalendarController sharedController] addObserver:self
                                                  forKeyPath:@"date"
                                                     options:NSKeyValueObservingOptionNew
                                                     context:NULL];
    }

    [defaults addObserver:self
               forKeyPath:WLAutoFadeKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    [defaults addObserver:self
               forKeyPath:WLAutoFadeSecondsKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];

    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
    [self deactivateAppIfAllConditionsAreMet:[NSApp windows]];
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

    [self deactivateAppIfAllConditionsAreMet:[NSApp windows]];
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
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
    NSMutableArray *visibleWindows = [[NSApp windows] mutableCopy];
    NSWindow *closedWindow = [aNotification object];
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
             [shortcutMenuItem setKeyEquivalent:[[NSValueTransformer valueTransformerForName:@"SRKeyEquivalentTransformer"] transformedValue:shortcut]];
             [shortcutMenuItem setKeyEquivalentModifierMask:[[[NSValueTransformer valueTransformerForName:@"SRKeyEquivalentModifierMaskTransformer"] transformedValue:shortcut] unsignedIntegerValue]];
         }
         else
         {
             [shortcutMenuItem setKeyEquivalent:@""];
             [shortcutMenuItem setKeyEquivalentModifierMask:0];
         }
     }];

    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
}


#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem
{
    if (aMenuItem == _newEventMenuItem)
        return [[WLNewEventWindowController sharedWindowController] canCreateEvent];
    else if (aMenuItem == _newTaskMenuItem)
        return [[WLNewTaskWindowController sharedWindowController] canCreateTask];
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
    BOOL isAutoFadeEnabled = [[NSUserDefaults standardUserDefaults] WL_autoFadeSeconds];
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
        [NSApp keyWindow] == [self.calendarWindowController window])
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
        [_applicationRunTimer tick];
    else if ([aKeyPath isEqualToString:WLAutoFadeKey] || [aKeyPath isEqualToString:WLAutoFadeSecondsKey])
    {
        if ([[NSUserDefaults standardUserDefaults] WL_autoFades])
            [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:[NSApp windows]];
        else
        {
            [self _removeAutoFadeTimerIfNeeded];
            self.calendarWindowController.isFadedOut = NO;
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:aObject change:aChange context:aContext];
}

@end
