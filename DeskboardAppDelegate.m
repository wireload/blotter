//
//  DeskboardAppDelegate.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "DeskboardAppDelegate.h"

@implementation DeskboardAppDelegate

@synthesize preferencesWindow;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = [[NSScreen mainScreen] visibleFrame];
    NSLog(@"Covering desktop (%f, %f, %f x %f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    desktopWindow  = [[NSWindow alloc] initWithContentRect:frame
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

    [desktopWindow orderFront:NSApp];
    // [desktopWindow useOptimizedDrawing:YES];
    [desktopWindow flushWindow];
    [desktopWindow display];
}


@end
