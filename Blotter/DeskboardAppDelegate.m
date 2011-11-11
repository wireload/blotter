//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

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

        // In pre 1.3 versions of Blotter CalendarSize was a string.
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

        // @see -[WLCalendarWindowController tasksViewFrame] for default value of TasksViewHeight.
    }
}

- (void)dealloc
{
    [calendarWindowController release];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObserver:self forKeyPath:@"ShowInMenuBar"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewEvent"];
    [userDefaults removeObserver:self forKeyPath:@"shortcutNewTask"];
    [_preferencesController release];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendarWindowController;


#pragma mark Methodsj

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
                                               NSLocalizedStringFromTableInBundle(@"Calendars", nil, [_preferencesController bundle], nil),
                                               NSLocalizedStringFromTableInBundle(@"Layout", nil, [_preferencesController bundle], nil),
                                               nil]];
        [_preferencesController createPreferencesWindow];
        [[_preferencesController preferencesWindow] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    }
    [_preferencesController showPreferencesWindow];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)newEvent:(id)aSender
{
    WLNewEventWindowController *controller = [WLNewEventWindowController sharedWindowController];
    [controller reset];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewEventWindowAutosaveName] == nil)
        [[controller window] center];
    [controller showWindow:aSender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)newTask:(id)aSender
{
    WLNewTaskWindowController *controller = [WLNewTaskWindowController sharedWindowController];
    [controller reset];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:_WLNewTaskWindowAutosaveName] == nil)
        [[controller window] center];
    [controller showWindow:aSender];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)showAbout:(id)aSender
{
    [NSApp orderFrontStandardAboutPanelWithOptions:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)isOnlyCalendarWindowVisible
{
    return [self _isOnlyCalendarWindowVisible:[NSApp windows]];
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
            [aMenuItem setKeyEquivalent:[shortcut objectForKey:SRShortcutCharactersIgnoringModifiers]];
            [aMenuItem setKeyEquivalentModifierMask:[[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue]];
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
            [aMenuItem setKeyEquivalent:[shortcut objectForKey:SRShortcutCharactersIgnoringModifiers]];
            [aMenuItem setKeyEquivalentModifierMask:[[shortcut objectForKey:SRShortcutFlagsKey] unsignedIntegerValue]];
        }
        else {
            [aMenuItem setKeyEquivalent:@""];
            [aMenuItem setKeyEquivalentModifierMask:0];
        }
        return [[WLNewTaskWindowController sharedWindowController] canCreateTask];
    }
    else
        return YES;
}


#pragma mark NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)aMenu
{
    [[calendarWindowController fadeController] fadeIn];
}

- (void)menuDidClose:(NSMenu *)aMenu
{
    if ([self isOnlyCalendarWindowVisible])
        [self.calendarWindowController.fadeController scheduleFadeOutTimer];
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

    calendarWindowController = [[WLCalendarWindowController alloc] init];
    [calendarWindowController showWindow:self];
    
    // Show preferences at first start.
    if ([userDefaults boolForKey:@"ShowPreferencesAtStartUp"])
    {
        [self showPreferences:self];
        [userDefaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self.calendarWindowController.fadeController fadeIn];
    
    if ([self isOnlyCalendarWindowVisible])
        [NSApp hide:self];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self.calendarWindowController.fadeController scheduleFadeOutTimer];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)anApplication hasVisibleWindows:(BOOL)aFlag
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInMenuBar"])
        [self showPreferences:self];
    return NO;
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
    else if ([aKeyPath isEqualToString:@"shortcutNewEvent"] || [aKeyPath isEqualToString:@"shortcutNewTask"])
    {
        PTHotKeyCenter *hotKeyCenter = [PTHotKeyCenter sharedCenter];
        PTHotKey *oldHotKey = [hotKeyCenter hotKeyWithIdentifier:aKeyPath];
        [hotKeyCenter unregisterHotKey:oldHotKey];

        NSDictionary *newHotKeyDict = [aChange objectForKey:NSKeyValueChangeNewKey];
        if (newHotKeyDict != nil && (id)newHotKeyDict != [NSNull null]) {
            PTHotKey *newHotKey = nil;
            if ([aKeyPath isEqualToString:@"shortcutNewEvent"]) {
                newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath keyCombo:newHotKeyDict target:self action:@selector(newEvent:)];
            }
            else {
                newHotKey = [PTHotKey hotKeyWithIdentifier:aKeyPath keyCombo:newHotKeyDict target:self action:@selector(newTask:)];
            }
            [hotKeyCenter registerHotKey:newHotKey];
        }
    }
}

@end
