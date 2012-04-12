//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "DeskboardAppDelegate.h"
#import "WLNewEventWindowController.h"
#import "WLNewTaskWindowController.h"
#import "SRCommon.h"
#import "PTHotKeyCenter.h"
#import "PTHotKey+ShortcutRecorder.h"
#import "WLCalendarWindow.h"
#import "WLCalendarWindowController.h"
#import "WLApplicationRunTimer.h"

enum {
    ShortcutsNameIdx,
    ShortcutsSelectorIdx,
    ShortcutsMenuItemIdx
};

extern NSString* const SRShortcutCodeKey;
extern NSString* const SRShortcutFlagsKey;
extern NSString* const SRShortcutCharacters;
extern NSString* const SRShortcutCharactersIgnoringModifiers;

// TODO: Update if the New Event/Task windows stop centering at first launch.
// Cocoa uses these strings to store frames of the New Event/Task windows in user defaults.
static NSString* const _WLNewEventWindowAutosaveName = @"NSWindow Frame NewEventWindow";
static NSString* const _WLNewTaskWindowAutosaveName = @"NSWindow Frame NewTaskWindow";


@implementation DeskboardAppDelegate

+ (void)initialize
{
    if (self == [DeskboardAppDelegate class])
    {
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
    [defaults removeObserver:self forKeyPath:@"ShowInMenuBar"];
    [_shortCuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *shortcutName = [obj objectAtIndex:ShortcutsNameIdx];
        [defaults removeObserver:self forKeyPath:shortcutName];
    }];
    if (_applicationRunTimer != nil)
        [[WLCalendarController sharedController] removeObserver:self forKeyPath:@"date"];
    [calendarWindowController release];
    [_preferencesController release];
    [_showCurrentWeekTimer invalidate];
    [_applicationRunTimer release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_autoFadeTimer invalidate];
    [defaults removeObserver:self forKeyPath:WLAutoFadeKey];
    [defaults removeObserver:self forKeyPath:WLAutoFadeSecondsKey];

    [_shortCuts release];
    _shortCuts = nil;
    [super dealloc];
}


#pragma mark Properties
@synthesize calendarWindowController;


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
        if ([self isOnlyCalendarWindowVisible:[NSApp windows]])
        {
            [NSApp activateIgnoringOtherApps:YES];
            [[self.calendarWindowController window] makeKeyWindow];
        }
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
    if (_preferencesController == nil) {
        // Determine path to the sample preference panes
        NSString *pathToPanes = [[[NSBundle mainBundle] resourcePath] stringByStandardizingPath];

        _preferencesController = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
        [_preferencesController setDebug:YES];

        // Set which panes are included, and their order.
        [_preferencesController setPanesOrder:[NSArray arrayWithObjects:
                                               NSLocalizedStringFromTableInBundle(@"General", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Shortcuts", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Positioning", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Layout", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Calendars", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"About", nil, [_preferencesController bundle], nil),
                                               nil]];
        [_preferencesController createPreferencesWindow];
        [[_preferencesController preferencesWindow] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [[[_preferencesController preferencesWindow] toolbar] insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:5];
        [[_preferencesController preferencesWindow] setLevel:NSFloatingWindowLevel];
    }
    [_preferencesController showPreferencesWindow];
    [self _removeAutoFadeTimerIfNeeded];
    self.calendarWindowController.isFadedOut = NO;
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)newEvent:(id)aSender
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

- (IBAction)newTask:(id)aSender
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
    [self showPreferences:aSender];
    NSToolbarItem *aboutItem = [[_preferencesController prefsToolbarItems] objectForKey:@"About"];
    [_preferencesController prefsToolbarItemClicked:aboutItem];
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
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:NO];
    [[NSWorkspace sharedWorkspace] openURL:[[NSUserDefaults standardUserDefaults] WL_rateThisAppURL]];
}

- (BOOL)isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows
{
    NSMutableArray *visibleWindows = [[aVisibleWindows mutableCopy] autorelease];
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


#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)aNotification
{
    NSMutableArray *visibleWindows = [[[NSApp windows] mutableCopy] autorelease];
    NSWindow *closedWindow = [aNotification object];
    [visibleWindows removeObjectIdenticalTo:closedWindow];
    [self deactivateAppIfAllConditionsAreMet:visibleWindows];
    [self scheduleAutoFadeCalendarWindowIfAllConditionsAreMet:visibleWindows];
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


#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)aMenu
{
    [_shortCuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        // If the menu item is nil, the shortcut definition will only be 2 items long. Ignore those.
        if ([obj count] < 3)
            return;

        NSString *shortcutName = [obj objectAtIndex:ShortcutsNameIdx];
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:shortcutName];
        NSMenuItem *shortcutMenuItem = [obj objectAtIndex:ShortcutsMenuItemIdx];

        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [shortcutMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [shortcutMenuItem setKeyEquivalentModifierMask:flags];
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


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _shortCuts = [[NSArray arrayWithObjects:
                  [NSArray arrayWithObjects:@"shortcutNewEvent", @"newEvent:", _newEventMenuItem, nil],
                  [NSArray arrayWithObjects:@"shortcutNewTask", @"newTask:", _newTaskMenuItem, nil],
                  [NSArray arrayWithObjects:@"shortcutShowNextWeek", @"showNextWeek:", _showNextWeekMenuItem, nil],
                  [NSArray arrayWithObjects:@"shortcutShowPreviousWeek", @"showPreviousWeek:", _showPreviousWeekMenuItem, nil],
                  [NSArray arrayWithObjects:@"shortcutShowCurrentWeek", @"showCurrentWeek:", _showCurrentWeekMenuItem, nil],
                  [NSArray arrayWithObjects:@"shortcutBringToFront", @"bringToFrontOrSendToBack:", _bringToFrontMenuItem, nil],
                  nil] retain];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Configure status bar
    if ([defaults boolForKey:@"ShowInMenuBar"])
        [self _addStatusItem];
    [defaults addObserver:self forKeyPath:@"ShowInMenuBar" options:NSKeyValueObservingOptionNew context:NULL];

    // Configure shortcuts
    [_shortCuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSString *shortcutName = [obj objectAtIndex:ShortcutsNameIdx];
        [defaults addObserver:self forKeyPath:shortcutName options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:obj];
    }];

    // Configure windows.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];
    calendarWindowController = [[WLCalendarWindowController alloc] init];
    [calendarWindowController showWindow:self];

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
        [[WLCalendarController sharedController] addObserver:self
                                                  forKeyPath:@"date"
                                                     options:NSKeyValueObservingOptionNew
                                                     context:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationRunTimerDidFire:) name:WLApplicationRunTimerDidFireNotification object:_applicationRunTimer];
    }

    [defaults addObserver:self
               forKeyPath:WLAutoFadeKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    [defaults addObserver:self
               forKeyPath:WLAutoFadeSecondsKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
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
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInMenuBar"])
        [self showPreferences:self];
    return NO;
}


#pragma mark Private

- (void)_addStatusItem
{
    NSAssert(_statusItem == nil, @"You cannot add status bar twice");
    _statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];;
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_statusMenu];

    NSImage *statusImage = [NSImage imageNamed:@"blotter-status-bar"];
    NSImage *statusHighlightImage = [NSImage imageNamed:@"blotter-status-bar-active"];
    [_statusItem setImage:statusImage];
    [_statusItem setAlternateImage:statusHighlightImage];
}

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

- (void)_autoFadeTimerDidFire;
{
    _autoFadeTimer = nil;
    if (![[NSUserDefaults standardUserDefaults] WL_autoFades])
        return;
    self.calendarWindowController.isFadedOut = YES;
}

- (void)_applicationRunTimerDidFire:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:YES];
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
    if (aContext != nil && [((id) aContext) isKindOfClass:[NSArray class]] && [((NSArray *) aContext) count] == 3)
    {
        // Shortcut.
        NSArray *obj = aContext;
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];

        NSDictionary *newHotKeyDict = [aChange objectForKey:NSKeyValueChangeNewKey];
        if (newHotKeyDict != nil && (id)newHotKeyDict != [NSNull null])
        {
            PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath keyCombo:newHotKeyDict target:self action:NSSelectorFromString([obj objectAtIndex:ShortcutsSelectorIdx])];
            [hotKeyCenter registerHotKey:newHotKey];
        }
        return;
    }

    if ([aKeyPath isEqualToString:@"ShowInMenuBar"])
    {
        if ([[aChange objectForKey:NSKeyValueChangeNewKey] boolValue])
            [self _addStatusItem];
        else
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
            [_statusItem release], _statusItem = nil;
        }
    }
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
