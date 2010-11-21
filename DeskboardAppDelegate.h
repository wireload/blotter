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

enum {
    BASmallSize = 0,
    BANormalSize = 1,
    BAFullSize = 2,

};

@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow    *desktopWindow;
    DesktopView *overlayView;

    SS_PrefsController *prefs;
}

- (IBAction)showPrefs:(id)sender;

- (void)layout;
@end
