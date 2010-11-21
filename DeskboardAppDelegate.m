//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "DeskboardAppDelegate.h"

@implementation DeskboardAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    desktopWindow  = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 0, 0)
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    // The -1 ensures we start out underneath the icons, not at the same level.
    [desktopWindow setLevel:kCGDesktopWindowLevel - 1];
    [desktopWindow setOpaque:NO];
    [desktopWindow setHasShadow:NO];
    [desktopWindow setBackgroundColor:[NSColor clearColor]];
    [desktopWindow setIgnoresMouseEvents:YES];

    overlayView = [[DesktopView alloc] initWithFrame:[[desktopWindow contentView] frame]];
    [desktopWindow setContentView:overlayView];

    [self layout];

    [desktopWindow orderFront:NSApp];
    // [desktopWindow useOptimizedDrawing:YES];
    [desktopWindow flushWindow];
    [desktopWindow display];
}


- (IBAction)showPrefs:(id)sender
{
    if (!prefs) {
        // Determine path to the sample preference panes
        NSString *pathToPanes = [[NSString stringWithFormat:@"%@/../Preference Panes/", [[NSBundle mainBundle] resourcePath]]
            stringByStandardizingPath];

        prefs = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
        [prefs setDebug:YES];

        // Set which panes are included, and their order.
        [prefs setPanesOrder:[NSArray arrayWithObjects:@"General", @"Positioning", nil]];
    }

    // Show the preferences window.
    [prefs showPreferencesWindow];
}

- (void)layout
{
    int sizePrefs = BANormalSize;

    CGSize size;

    switch (sizePrefs) {
        case BANormalSize:
            size = CGSizeMake(1200, 800);
            break;
        default:
            break;
    }

    NSRect frame = [[NSScreen mainScreen] visibleFrame];
    NSLog(@"Covering desktop (%f, %f, %f x %f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);

    [desktopWindow setFrame:NSMakeRect(10, 10, size.width, size.height) display:YES];
}

- (void)dealloc
{
    [prefs release];
    [super dealloc];
}

@end
