//
//  DeskboardAppDelegate.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 31/10/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DesktopView.h"

@interface DeskboardAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow    *preferencesWindow;
    NSWindow    *desktopWindow;
    DesktopView *overlayView;
}

@property (assign) IBOutlet NSWindow *preferencesWindow;

@end
