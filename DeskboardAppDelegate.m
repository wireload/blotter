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

    // Show prefs at first start
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *showPrefsAtStartup = [userDefaults objectForKey:@"ShowPreferencesAtStartUp"];
    if (showPrefsAtStartup == nil || [showPrefsAtStartup boolValue]) {
        [self showPrefs:self];
        [userDefaults setBool:NO forKey:@"ShowPreferencesAtStartUp"];
    }

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

    // [blotterWindow useOptimizedDrawing:YES];

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
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self show];
}

-(void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
    [self show];
}

- (void)showOnScreen:(NSScreen *)screen
{
    if (![blotterWindow fitWithinFrame:[screen visibleFrame]])
        [(DesktopView *)[blotterWindow contentView] refresh];

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

    if (usedScreenIdx != NSNotFound)
        [self showOnScreen:[screens objectAtIndex:usedScreenIdx]];
}

- (void)dealloc
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
    [blotterWindow release];
    [prefs release];
    [super dealloc];
}

@end
