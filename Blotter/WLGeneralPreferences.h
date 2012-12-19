//
//  WLGeneralPreferences.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLViewController.h"
#import "IKPreferencesRepresentation.h"


@class WLPrefPaneView;


@interface WLGeneralPreferences : WLViewController <NSAlertDelegate, IKPreferencesRepresentation>

- (IBAction)quitBlotter:(id)aSender;

- (IBAction)showMacOSXCalendarSettings:(id)aSender;

@end
