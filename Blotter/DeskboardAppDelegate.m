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
    [calendarWindowController release];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"ShowInMenuBar"];
    [_shortCuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        NSString *shortcutName = [obj objectAtIndex:ShortcutsNameIdx];
        [userDefaults removeObserver:self forKeyPath:shortcutName];
    }];

    if (_applicationRunTimer != nil)
        [[WLCalendarController sharedController] removeObserver:self forKeyPath:@"date"];
    [_preferencesController release];
    [_showCurrentWeekTimer invalidate];
    [_applicationRunTimer release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_shortCuts release];
    _shortCuts = nil;
    [super dealloc];
}


#pragma mark Properties
@synthesize calendarWindowController;


#pragma mark Methods

- (IBAction)bringToFront:(id)sender {
    WLCalendarWindow *calendarWindow = self.calendarWindowController.window;
    if (calendarWindow.state == WLFinderLevelState)
    {
        [[calendarWindowController fadeController] fadeIn];
        [calendarWindow levelUp];
    }
    else 
    {
        [calendarWindow levelDown];
        if ([self _isOnlyCalendarWindowVisible:[NSApp windows]])
            [NSApp hide:self];
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
    }
    [_preferencesController showPreferencesWindow];
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
            [self autohideCalendarWindowIfAllConditionsAreMet];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [[calendarWindowController fadeController] fadeIn];
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
            [self autohideCalendarWindowIfAllConditionsAreMet];
        }
        else
        {
            [self _scheduleShowCurrentWeekTimerIfNeeded];
            [[calendarWindowController fadeController] fadeIn];
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
        [self autohideCalendarWindowIfAllConditionsAreMet];
    }
    else
        NSBeep();
}

- (IBAction)showRateThisApp:(id)aSender
{
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:NO];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"macappstore://itunes.apple.com/app/id406580224?mt=12"]];
}

- (BOOL)isOnlyCalendarWindowVisible
{
    return [self _isOnlyCalendarWindowVisible:[NSApp windows]];
}

- (void)autohideCalendarWindowIfAllConditionsAreMet
{
    BOOL isBlotterActive = [NSApp isActive];
    BOOL areThereUtilityWindows = ![self isOnlyCalendarWindowVisible];
    BOOL isCurrentWeekShowed = [self.calendarWindowController isCurrentWeekShowed];
    if ((!isBlotterActive && !areThereUtilityWindows && isCurrentWeekShowed) ||
        (!isBlotterActive && areThereUtilityWindows && isCurrentWeekShowed) ||
        (isBlotterActive && !areThereUtilityWindows && isCurrentWeekShowed))
    {
        [self.calendarWindowController.fadeController scheduleFadeOutTimer];
    }
}


#pragma mark NSWindowDelegate

- (void)windowWillClose:(NSNotification *)aNotification
{
    NSMutableArray *visibleWindows = [[[NSApp windows] mutableCopy] autorelease];
    NSWindow *closedWindow = [aNotification object];
    [visibleWindows removeObjectIdenticalTo:closedWindow];
    if ([self _isOnlyCalendarWindowVisible:visibleWindows])
        [NSApp hide:self];
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
        if (self.calendarWindowController.window.state != WLFinderLevelState)
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

    [[calendarWindowController fadeController] fadeIn];
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    [self autohideCalendarWindowIfAllConditionsAreMet];
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
                  [NSArray arrayWithObjects:@"shortcutBringToFront", @"bringToFront:", _bringToFrontMenuItem, nil],
                  nil] retain];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // Configure status bar
    if ([userDefaults boolForKey:@"ShowInMenuBar"])
        [self _addStatusItem];
    [userDefaults addObserver:self forKeyPath:@"ShowInMenuBar" options:NSKeyValueObservingOptionNew context:NULL];

    // Configure shortcuts
    [_shortCuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
    {
        NSString *shortcutName = [obj objectAtIndex:ShortcutsNameIdx];
        [userDefaults addObserver:self forKeyPath:shortcutName options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:obj];
    }];

    // Configure windows.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];

    calendarWindowController = [[WLCalendarWindowController alloc] init];
    [calendarWindowController showWindow:self];

    // Show preferences at first start.
    if ([userDefaults boolForKey:@"ShowPreferencesAtStartUp"])
    {
        [self showPreferences:self];
        [userDefaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }

    [self autohideCalendarWindowIfAllConditionsAreMet];

    // Configure application run timer.
    if (![userDefaults WL_applicationRunTimerIsFired])
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
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self.calendarWindowController.fadeController fadeIn];

    if ([self isOnlyCalendarWindowVisible] && calendarWindowController.window.state == WLFinderLevelState)
        [NSApp hide:self];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self autohideCalendarWindowIfAllConditionsAreMet];
    if (calendarWindowController.window.state != WLFinderLevelState)
        [calendarWindowController.window levelDown];
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

- (BOOL)_isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows
{
    NSMutableArray *visibleWindows = [[aVisibleWindows mutableCopy] autorelease];
    [visibleWindows filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSWindow *w, NSDictionary *bindings) {
        return [w isVisible] && ![[w className] hasPrefix:@"NSStatusBarWindow"];
    }]];
    return ([visibleWindows count] == 1); // If only desktop window is visible
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

- (void)_applicationRunTimerDidFire:(NSNotification *)aNotification
{
    [[NSUserDefaults standardUserDefaults] WL_setShowRateThisAppInMenu:YES];
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
    else
        [super observeValueForKeyPath:aKeyPath ofObject:aObject change:aChange context:aContext];
}

@end
