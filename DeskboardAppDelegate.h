//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SS_PrefsController.h"

#import "DesktopView.h"
#import "BLCalendarFramer.h"


@class WLCalendarWindowController;

@class WLFitWindow;

@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate> {
    WLCalendarWindowController *windowController;
//    WLFitWindow *blotterWindow;
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *newEventMenuItem;
    IBOutlet NSMenuItem *newTaskMenuItem;
    IBOutlet NSMenuItem *preferencesMenuItem;
    BOOL ignoreBecomeActiveNotification;

    SS_PrefsController *prefs;
}

- (IBAction)showPrefs:(id)sender;

- (IBAction)newEvent:(id)sender;

- (IBAction)newTask:(id)sender;

//- (void)showOnScreen:(NSScreen *)screen;
//
//- (void)show;

@end
