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

@interface DeskboardAppDelegate (/* Private */)

- (void)_addStatusItem;

@end


@implementation DeskboardAppDelegate

+ (void)initialize
{
    if (self == [DeskboardAppDelegate class])
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

        if ([userDefaults objectForKey:@"DisplayAllCalendars"] == nil)
            // Enabled by default
            [userDefaults setObject:[NSNumber numberWithInteger:1] forKey:@"DisplayAllCalendars"];

        NSArray *calendars = [userDefaults arrayForKey:@"Calendars"];
        if (calendars == nil)
            [userDefaults setObject:[NSArray array] forKey:@"Calendars"];

        if ([userDefaults objectForKey:@"CalendarSize"] == nil)
            [userDefaults setInteger:BLNormalSize forKey:@"CalendarSize"];
        else {
            if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Narrow"])
                [userDefaults setInteger:BLNarrowSize forKey:@"CalendarSize"];
            else if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Normal"])
                [userDefaults setInteger:BLNormalSize forKey:@"CalendarSize"];
            else if ([[userDefaults stringForKey:@"CalendarSize"] isEqualToString:@"Full"])
                [userDefaults setInteger:BLFullSize forKey:@"CalendarSize"];
        }

        if ([userDefaults objectForKey:@"ScreenIdentifier"] == nil)
        {
            NSNumber *mainScreenID = [[[NSScreen mainScreen] deviceDescription] objectForKey:@"NSScreenNumber"];
            [userDefaults setObject:mainScreenID forKey:@"ScreenIdentifier"];
        }

        if ([userDefaults objectForKey:@"ShowInMenuBar"] == nil)
            [userDefaults setBool:YES forKey:@"ShowInMenuBar"];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.CalendarPosition"
                                                                 options:0
                                                                 context:NULL];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.CalendarSize"
                                                                 options:0
                                                                 context:NULL];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.ScreenIdentifier"
                                                                 options:0
                                                                 context:NULL];

    blotterWindow = [[WLFitWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                                   styleMask:NSBorderlessWindowMask
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [blotterWindow setOpaque:NO];
    [blotterWindow setHasShadow:NO];
    [blotterWindow setBackgroundColor:[NSColor clearColor]];
    [blotterWindow setIgnoresMouseEvents:YES];
    [blotterWindow setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];

    DesktopView *overlayView = [[DesktopView alloc] initWithFrame:[[blotterWindow contentView] frame]];
    [blotterWindow setContentView:overlayView];
    [overlayView release];
    [blotterWindow setDelegate:self];

    // [blotterWindow useOptimizedDrawing:YES];

    [self show];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *showPrefsAtStartup = [userDefaults objectForKey:@"ShowPreferencesAtStartUp"];
    if (showPrefsAtStartup == nil || [showPrefsAtStartup boolValue]) {
        // TODO: 1.3 Show about pref pane at first start.
        [self showPrefs:self];
        [userDefaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }

    if ([userDefaults boolForKey:@"ShowInMenuBar"])
        [self _addStatusItem];

    [userDefaults addObserver:self forKeyPath:@"ShowInMenuBar" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"ShowInMenuBar"])
        [self showPrefs:self];
}

-(void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
    [self show];
}

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
                              NSLocalizedStringFromTableInBundle(@"Calendars", nil, [prefs bundle], nil), nil]];
    }

    // Show the preferences window.
    [prefs showPreferencesWindow];
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
    else
        [self show];
}

- (void)showOnScreen:(NSScreen *)screen
{
    [blotterWindow fitWithinFrame:[screen visibleFrame]];

    if (![blotterWindow isVisible])
    {
        // Not -1 anymore because that causes Blotter to disappear underneath the
        // wallpaper under certain (rare) circumstances, like when Quiet activates.
        [blotterWindow setLevel:kCGDesktopWindowLevel];
        // Order back to get underneath the icons.
        [blotterWindow orderBack:NSApp];
    }
}

- (void)show
{
    NSNumber *usedScreenID = [[NSUserDefaults standardUserDefaults] objectForKey:@"ScreenIdentifier"];
    NSArray *screens = [NSScreen screens];
    NSUInteger usedScreenIdx = [screens indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
    {
        return (BOOL)([[[obj deviceDescription] objectForKey:@"NSScreenNumber"] isEqualToNumber:usedScreenID]);
    }];

    // If user selected screen is connected, use it. Otherwise use screen with main menu.
    if (usedScreenIdx != NSNotFound)
        [self showOnScreen:[screens objectAtIndex:usedScreenIdx]];
    else
        [self showOnScreen:[[NSScreen screens] objectAtIndex:0]];

}

- (void)dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
    [blotterWindow release];
    [prefs release];
    [super dealloc];
}

- (void)_addStatusItem
{
    NSAssert(statusItem == nil, @"You cannot add status bar twice");
    // Configure system-wide menubar item
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];;
    [statusItem setTitle:@"Blotter"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
}


#pragma mark NSWindowDelegate

- (void)windowDidResize:(NSNotification *)notification
{
    [(DesktopView *)[blotterWindow contentView] refresh];
}

@end
