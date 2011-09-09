//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "DeskboardAppDelegate.h"
#import "BLPositionerControl.h"
#import "BLCalendarFramer.h"
#import "WLFitWindow.h"
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

// TODO: Update if New Event/Task windows stop centering at first launch.
// Cocoa uses these strings to store frames of the new event/task windows in user defaults.
static NSString* const _WLNewEventWindowAutosaveName = @"NSWindow Frame NewEventWindow";
static NSString* const _WLNewTaskWindowAutosaveName = @"NSWindow Frame NewTaskWindow";


@interface DeskboardAppDelegate (/* Private */)

- (void)_addStatusItem;

@end


@implementation DeskboardAppDelegate

+ (void)initialize
{
    if (self == [DeskboardAppDelegate class])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Narrow"])
            [userDefaults setInteger:BLNarrowSize forKey:@"CalendarSize"];
        else if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Normal"])
            [userDefaults setInteger:BLNormalSize forKey:@"CalendarSize"];
        else if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Full"])
            [userDefaults setInteger:BLFullSize forKey:@"CalendarSize"];

        if ([userDefaults objectForKey:@"ScreenIdentifier"] == nil)
        {
            NSNumber *mainScreenID = [[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"];
            [userDefaults setObject:mainScreenID forKey:@"ScreenIdentifier"];
        }

        NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
        NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
        [userDefaults registerDefaults:defaults];
    }
}

- (void)dealloc
{
//    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
    [windowController release];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"ShowInMenuBar"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewEvent"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewTask"];
//    [blotterWindow release];
    [prefs release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
//                                                              forKeyPath:@"values.CalendarPosition"
//                                                                 options:0
//                                                                 context:NULL];
//    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
//                                                              forKeyPath:@"values.CalendarSize"
//                                                                 options:0
//                                                                 context:NULL];
//    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
//                                                              forKeyPath:@"values.ScreenIdentifier"
//                                                                 options:0
//                                                                 context:NULL];

    // Configure Blotter
//    blotterWindow = [[WLFitWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
//                                                   styleMask:NSBorderlessWindowMask
//                                                     backing:NSBackingStoreBuffered
//                                                       defer:NO];
//    [blotterWindow setOpaque:NO];
//    [blotterWindow setHasShadow:NO];
//    [blotterWindow setBackgroundColor:[NSColor clearColor]];
//    [blotterWindow setIgnoresMouseEvents:YES];
//    [blotterWindow setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];
//    DesktopView *overlayView = [[DesktopView alloc] initWithFrame:[[blotterWindow contentView] frame]];
//    [blotterWindow setContentView:overlayView];
//    [overlayView release];
//    [blotterWindow setDelegate:self];
//    [self show];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // Show preferences at first start.
    NSNumber *showPrefsAtStartup = [userDefaults objectForKey:@"ShowPreferencesAtStartUp"];
    if (showPrefsAtStartup == nil || [showPrefsAtStartup boolValue]) {
        // TODO: 1.3 Show about pref pane at first start.
        [self showPrefs:self];
        [userDefaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }

    // Configure status bar
    if ([userDefaults boolForKey:@"ShowInMenuBar"])
        [self _addStatusItem];
    [userDefaults addObserver:self forKeyPath:@"ShowInMenuBar" options:NSKeyValueObservingOptionNew context:NULL];

    // Configure shortcuts
    NSDictionary *newEventShortcut = [userDefaults dictionaryForKey:@"shortcutNewEvent"];
    if (newEventShortcut != nil) {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutNewEvent" keyCombo:newEventShortcut target:self action:@selector(newEvent:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    NSDictionary *newTaskShortcut = [userDefaults dictionaryForKey:@"shortcutNewTask"];
    if (newTaskShortcut != nil) {
        PTHotKey *hotKey = [PTHotKey hotKeyWithIdentifier:@"shortcutNewTask" keyCombo:newTaskShortcut target:self action:@selector(newTask:)];
        [[PTHotKeyCenter sharedCenter] registerHotKey:hotKey];
    }
    [userDefaults addObserver:self forKeyPath:@"shortcutNewEvent" options:NSKeyValueObservingOptionNew context:NULL];
    [userDefaults addObserver:self forKeyPath:@"shortcutNewTask" options:NSKeyValueObservingOptionNew context:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];

    windowController = [[WLCalendarWindowController alloc] init];
    [windowController bind:@"windowSize"
                  toObject:[NSUserDefaultsController sharedUserDefaultsController]
               withKeyPath:@"values.CalendarSize"
                   options:nil];
    [windowController bind:@"windowPosition"
                  toObject:[NSUserDefaultsController sharedUserDefaultsController]
               withKeyPath:@"values.CalendarPosition"
                   options:nil];
    [windowController bind:@"windowScreenIdentifier"
                  toObject:[NSUserDefaultsController sharedUserDefaultsController]
               withKeyPath:@"values.ScreenIdentifier"
                   options:nil];
    [windowController showWindow:self];
}

/*!
* @discussion There are a few exclusion when this message should be ignored:
* 1) User press the new event shortcut
* 2) User press the new task shortcut
 */
- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (!ignoreBecomeActiveNotification && ![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInMenuBar"]) {
        [self showPrefs:self];
    }
    ignoreBecomeActiveNotification = NO;
}

//-(void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
//{
//    [self show];
//}

- (IBAction)showPrefs:(id)sender
{
    if (!prefs) {
        // Determine path to the sample preference panes
        NSString *pathToPanes = [[[NSBundle mainBundle] resourcePath] stringByStandardizingPath];

        prefs = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
        [prefs setDebug:YES];

        // Set which panes are included, and their order.
        [prefs setPanesOrder:[NSArray arrayWithObjects:NSLocalizedStringFromTableInBundle(@"General", nil, [prefs bundle], nil),
                              NSLocalizedStringFromTableInBundle(@"Positioning", nil, [prefs bundle], nil),
                              NSLocalizedStringFromTableInBundle(@"Calendars", nil, [prefs bundle], nil),
                              NSLocalizedStringFromTableInBundle(@"Layout", nil, [prefs bundle], nil),
                              nil]];
        [prefs createPreferencesWindow];
        [[prefs preferencesWindow] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    }

    // Show the preferences window.
    [prefs showPreferencesWindow];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)newEvent:(id)sender
{
    WLNewEventWindowController *controller = [WLNewEventWindowController sharedWindowController];
    [controller reset];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewEventWindowAutosaveName] == nil)
        [[controller window] center];
    [controller showWindow:sender];
    ignoreBecomeActiveNotification = YES;
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)newTask:(id)sender
{
    WLNewTaskWindowController *controller = [WLNewTaskWindowController sharedWindowController];
    [controller reset];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewTaskWindowAutosaveName] == nil)
        [[controller window] center];
    [controller showWindow:sender];
    ignoreBecomeActiveNotification = YES;
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"ShowInMenuBar"])
    {
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue])
            [self _addStatusItem];
        else
        {
            [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
            [statusItem release], statusItem = nil;
        }
    }
    else if ([keyPath isEqualToString:@"shortcutNewEvent"] || [keyPath isEqualToString:@"shortcutNewTask"])
    {
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:keyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];

        NSDictionary *newHotKeyDict = [change objectForKey:NSKeyValueChangeNewKey];
        if (newHotKeyDict != nil && (id)newHotKeyDict != [NSNull null]) {
            PTHotKey *newHotKey = nil;
            if ([keyPath isEqualToString:@"shortcutNewEvent"]) {
                newHotKey = [PTHotKey hotKeyWithIdentifier:keyPath keyCombo:newHotKeyDict target:self action:@selector(newEvent:)];
            }
            else {
                newHotKey = [PTHotKey hotKeyWithIdentifier:keyPath keyCombo:newHotKeyDict target:self action:@selector(newTask:)];
            }
            [hotKeyCenter registerHotKey:newHotKey];
        }
    }
//    else
//        [self show];
}

//- (void)showOnScreen:(NSScreen *)screen
//{
//    [blotterWindow fitWithinFrame:[screen visibleFrame]];
//
//    if (![blotterWindow isVisible])
//    {
//        // Not -1 anymore because that causes Blotter to disappear underneath the
//        // wallpaper under certain (rare) circumstances, like when Quiet activates.
//        [blotterWindow setLevel:kCGDesktopWindowLevel];
//        [blotterWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
//        // Order back to get underneath the icons.
//        [blotterWindow orderBack:NSApp];
//    }
//}

//- (void)show
//{
//    NSNumber *usedScreenID = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScreenIdentifier"];
//    NSArray *screens = [NSScreen screens];
//    NSUInteger usedScreenIdx = [screens indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
//    {
//        return (BOOL)([[[obj deviceDescription] objectForKey:@"NSScreenNumber"] isEqualToNumber:usedScreenID]);
//    }];
//
//    // If user selected screen is connected, use it. Otherwise use screen with main menu.
//    if (usedScreenIdx != NSNotFound)
//        [self showOnScreen:[screens objectAtIndex:usedScreenIdx]];
//    else
//        [self showOnScreen:[[NSScreen screens] objectAtIndex:0]];
//
//}


#pragma mark Private

- (void)_addStatusItem
{
    NSAssert(statusItem == nil, @"You cannot add status bar twice");
    // Configure system-wide menubar item
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];;
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];

    NSImage *statusImage = [NSImage imageNamed:@"blotter-status-bar"];
    NSImage *statusHighlightImage = [NSImage imageNamed:@"blotter-status-bar-active"];
    [statusItem setImage:statusImage];
    [statusItem setAlternateImage:statusHighlightImage];
}


#pragma mark NSWindowDelegate

//- (void)windowDidResize:(NSNotification *)notification
//{
//    id window = [notification object];
//    if ([window isKindOfClass:[DesktopView class]])
//        [[window contentView] refresh];
//}

- (void)windowWillClose:(NSNotification *)notification
{
    NSMutableArray *visibleWindows = [[[NSApp windows] mutableCopy] autorelease];
    [visibleWindows removeObjectIdenticalTo:[notification object]];
    [visibleWindows filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSWindow *w, NSDictionary *bindings) {
        return [w isVisible] && ![[w className] hasPrefix:@"NSStatusBarWindow"];
    }]];
    if ([visibleWindows count] == 1) // If only desktop window is visible
        [NSApp hide:self];
}


#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)aMenuItem {
    if (aMenuItem == newEventMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutNewEvent"];
        if (shortcut != nil) {
            [aMenuItem setKeyEquivalent:[shortcut objectForKey:SRShortcutCharactersIgnoringModifiers]];
            [aMenuItem setKeyEquivalentModifierMask:[[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue]];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [WLNewEventWindowController canCreateEvent];
    }
    else if (aMenuItem == newTaskMenuItem)
    {
        NSDictionary *shortcut = [[NSUserDefaults standardUserDefaults] objectForKey:@"shortcutNewTask"];
        if (shortcut != nil) {
            [aMenuItem setKeyEquivalent:[shortcut objectForKey:SRShortcutCharactersIgnoringModifiers]];
            [aMenuItem setKeyEquivalentModifierMask:[[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue]];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [WLNewTaskWindowController canCreateTask];
    }
    else
        return YES;
}


#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu
{
    [[windowController fadeController] fadeIn];
}

@end
