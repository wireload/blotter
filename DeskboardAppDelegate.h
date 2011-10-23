//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowController.h"


@class SS_PrefsController;


@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate> {
    WLCalendarWindowController *calendarWindowController;

    NSStatusItem *_statusItem;
    IBOutlet NSMenu *_statusMenu;
    IBOutlet NSMenuItem *_newEventMenuItem;
    IBOutlet NSMenuItem *_newTaskMenuItem;
    IBOutlet NSMenuItem *preferencesMenuItem;
    SS_PrefsController *_preferencesController;
}

@property (readonly) WLCalendarWindowController *calendarWindowController;

- (IBAction)showPreferences:(id)aSender;

- (IBAction)newEvent:(id)aSender;

- (IBAction)newTask:(id)aSender;

- (IBAction)showAbout:(id)aSender;

/*!
 @abstract Determines whether only calendar window is visible.
 */
- (BOOL)isOnlyCalendarWindowVisible;


- (BOOL)_isOnlyCalendarWindowVisible:(NSArray *)aVisibleWindows;

- (void)_addStatusItem;

@end
