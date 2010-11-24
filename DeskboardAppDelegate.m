//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "DeskboardAppDelegate.h"
#import "BLPositionerControl.h"

const NSSize BLNarrowMinimumSize = {270, 750};
const NSSize BLNormalMinimumSize = {801, 750};

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
    [desktopWindow setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];

    overlayView = [[DesktopView alloc] initWithFrame:[[desktopWindow contentView] frame]];
    [desktopWindow setContentView:overlayView];

    [self layout];

    [desktopWindow orderFront:NSApp];
    // [desktopWindow useOptimizedDrawing:YES];

    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.CalendarPosition"
                                                                 options:0
                                                                 context:NULL];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                              forKeyPath:@"values.CalendarSize"
                                                                 options:0
                                                                 context:NULL];
}


- (IBAction)showPrefs:(id)sender
{
    if (!prefs) {
        // Determine path to the sample preference panes
        NSString *pathToPanes = [[[NSBundle mainBundle] resourcePath] stringByStandardizingPath];

        prefs = [[SS_PrefsController alloc] initWithPanesSearchPath:pathToPanes];
        [prefs setDebug:YES];

        // Set which panes are included, and their order.
        [prefs setPanesOrder:[NSArray arrayWithObjects:@"General", @"Positioning", nil]];
    }

    // Show the preferences window.
    [prefs showPreferencesWindow];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"Resizing due to %@ settings change", keyPath);
    [self layout];
}

- (void)layout
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *sizeSetting = [defaults stringForKey:@"CalendarSize"];
    int sizePrefs = BLNormalSize;
    if ([sizeSetting isEqualToString:@"Narrow"])
        sizePrefs = BLNarrowSize;
    else if ([sizeSetting isEqualToString:@"Full"])
        sizePrefs = BLFullSize;

    NSSize size;
    NSRect frame = [[NSScreen mainScreen] visibleFrame];

    switch (sizePrefs) {
        case BLNarrowSize:
            size = BLNarrowMinimumSize;
            break;
        case BLFullSize:
            size = NSMakeSize(frame.size.width - 20, frame.size.height - 20);
            break;
        default:
            size = NSMakeSize(MAX(BLNormalMinimumSize.width, frame.size.width / 2), MAX(BLNormalMinimumSize.height, frame.size.height / 2));
            break;
    }

    CGFloat px = 10;
    CGFloat py = 10;

    int aPosition = MIN(BLPositionBottomRight, MAX(BLPositionTopLeft, [defaults integerForKey:@"CalendarPosition"]));

    if (aPosition == BLPositionTopCenter ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionBottomCenter)
        px = floor(frame.size.width / 2.0 - size.width / 2.0);

    if (aPosition == BLPositionTopRight ||
        aPosition == BLPositionCenterRight ||
        aPosition == BLPositionBottomRight)
        px = frame.size.width - size.width - 10;

    if (aPosition == BLPositionTopLeft ||
        aPosition == BLPositionTopCenter ||
        aPosition == BLPositionTopRight)
        py = frame.size.height - size.height - 10;

    if (aPosition == BLPositionCenterLeft ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionCenterRight)
        py = floor(frame.size.height / 2.0 - size.height / 2.0);


    NSRect desiredFrame = NSMakeRect(px, py, size.width, size.height);
    NSLog(@"Placing at %@", NSStringFromRect(desiredFrame));

    [desktopWindow setFrame:desiredFrame display:YES];

    // FIXME Only do this if the size actually changed. Also, the view should do this by itself.
    [overlayView refresh];
}

- (void)dealloc
{
    [prefs release];
    [super dealloc];
}

@end
