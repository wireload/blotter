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


@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate> {
    NSMutableDictionary *screenWindows;

    SS_PrefsController *prefs;
}

- (IBAction)showPrefs:(id)sender;

- (void)showOnScreen:(NSScreen *)screen;

- (void)show;

@end
