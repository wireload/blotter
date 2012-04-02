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
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewEvent"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewTask"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutShowNextWeek"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutShowPreviousWeek"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutShowCurrentWeek"];
    [_preferencesController release];
    [_showCurrentWeekTimer invalidate];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendarWindowController;


#pragma mark Methods

- (IBAction)showPreferences:(id)aSender
{
    if (_preferencesController == nil) {
        // Determine path to the sample preference panes
        NSString *pathToPanes = [[[NSBundle mainBundle] resourcePath] stringByStandardizingPath];

        _preferencesController = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
        [_preferencesController setDebug:YES];

        // Set which panes are included, and their order.
        [_preferencesController setPanesOrder:[NSArray arrayWithObjects:NSLocalizedStringFromTableInBundle(@"General", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Positioning", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Layout", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Calendars", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"About", nil, [_preferencesController bundle], nil),
                                               nil]];
        [_preferencesController createPreferencesWindow];
        [[_preferencesController preferencesWindow] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        [[[_preferencesController preferencesWindow] toolbar] insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:4];
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

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem {
    if (aMenuItem == _newEventMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutNewEvent"];
        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [aMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [aMenuItem setKeyEquivalentModifierMask:flags];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [[WLNewEventWindowController sharedWindowController] canCreateEvent];
    }
    else if (aMenuItem == _newTaskMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutNewTask"];
        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [aMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [aMenuItem setKeyEquivalentModifierMask:flags];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [[WLNewTaskWindowController sharedWindowController] canCreateTask];
    }
    else if (aMenuItem == _showNextWeekMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutShowNextWeek"];
        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [aMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [aMenuItem setKeyEquivalentModifierMask:flags];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [self.calendarWindowController canShowNextWeek];
    }
    else if (aMenuItem == _showCurrentWeekMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutShowCurrentWeek"];
        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [aMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [aMenuItem setKeyEquivalentModifierMask:flags];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [self.calendarWindowController canShowCurrentWeek];
    }
    else if (aMenuItem == _showPreviousWeekMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutShowPreviousWeek"];
        if (shortcut != nil) {
            NSInteger code = [[shortcut objectForKey:SRShortcutCodeKey] integerValue];
            NSUInteger flags = [[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue];
            [aMenuItem setKeyEquivalent:SRASCIIStringForKeyCode(code)];
            [aMenuItem setKeyEquivalentModifierMask:flags];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [self.calendarWindowController canShowPreviousWeek];
    }
    else
        return YES;
}


#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)aMenu
{
    [[calendarWindowController fadeController] fadeIn];
    _calendarWindowLevelBeforeMenuWasShown = [self.calendarWindowController.window level];
    [self.calendarWindowController.window levelUp];
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    [self.calendarWindowController.window levelDown];
    [self autohideCalendarWindowIfAllConditionsAreMet];
}


#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // Configure status bar
    if ([userDefaults boolForKey:@"ShowInMenuBar"])
        [self _addStatusItem];
    [userDefaults addObserver:self forKeyPath:@"ShowInMenuBar" options:NSKeyValueObservingOptionNew context:NULL];

    // Configure shortcuts
    NSDictionary *newEventShortcut = [userDefaults dictionaryForKey:@"shortcutNewEvent"];
    if (newEventShortcut != nil)
    {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutNewEvent" keyCombo:newEventShortcut target:self action:@selector(newEvent:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    NSDictionary *newTaskShortcut = [userDefaults dictionaryForKey:@"shortcutNewTask"];
    if (newTaskShortcut != nil)
    {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutNewTask" keyCombo:newTaskShortcut target:self action:@selector(newTask:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    NSDictionary *showNextWeekShortcut = [userDefaults dictionaryForKey:@"shortcutShowNextWeek"];
    if (showNextWeekShortcut != nil)
    {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutShowNextWeek" keyCombo:showNextWeekShortcut target:self action:@selector(showNextWeek:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    NSDictionary *showPreviousWeekShortcut = [userDefaults dictionaryForKey:@"shortcutShowPreviousWeek"];
    if (showNextWeekShortcut != nil)
    {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutShowPreviousWeek" keyCombo:showPreviousWeekShortcut target:self action:@selector(showPreviousWeek:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    NSDictionary *showCurrentWeekShortcut = [userDefaults dictionaryForKey:@"shortcutShowCurrentWeek"];
    if (showNextWeekShortcut != nil)
    {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutShowCurrentWeek" keyCombo:showCurrentWeekShortcut target:self action:@selector(showCurrentWeek:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    [userDefaults addObserver:self forKeyPath:@"shortcutNewEvent" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"shortcutNewTask" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"shortcutShowNextWeek" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"shortcutShowPreviousWeek" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"shortcutShowCurrentWeek" options:NSKeyValueObservingOptionNew context:NULL];

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
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self.calendarWindowController.fadeController fadeIn];

    if ([self isOnlyCalendarWindowVisible])
        [NSApp hide:self];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self autohideCalendarWindowIfAllConditionsAreMet];
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


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)aObject change:(NSDictionary *)aChange context:(void *)aContext
{
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
    else if ([aKeyPath isEqualToString:@"shortcutNewEvent"] ||
             [aKeyPath isEqualToString:@"shortcutNewTask"] ||
             [aKeyPath isEqualToString:@"shortcutShowNextWeek"] ||
             [aKeyPath isEqualToString:@"shortcutShowPreviousWeek"] ||
             [aKeyPath isEqualToString:@"shortcutShowCurrentWeek"])
    {
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];

        NSDictionary *newHotKeyDict = [aChange objectForKey:NSKeyValueChangeNewKey];
        if (newHotKeyDict != nil && (id)newHotKeyDict != [NSNull null])
        {
            SEL action = NULL;
            if ([aKeyPath isEqualToString:@"shortcutNewEvent"])
                action = @selector(newEvent:);
            else if ([aKeyPath isEqualToString:@"shortcutNewTask"])
                action = @selector(newTask:);
            else if ([aKeyPath isEqualToString:@"shortcutShowNextWeek"])
                action = @selector(showNextWeek:);
            else if ([aKeyPath isEqualToString:@"shortcutShowPreviousWeek"])
                action = @selector(showPreviousWeek:);
            else
                action = @selector(showCurrentWeek:);
            PTHotKey *newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath keyCombo:newHotKeyDict target:self action:action];
            [hotKeyCenter registerHotKey:newHotKey];
        }
    }
}

@end
