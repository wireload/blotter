//
//  GeneralPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLPrefPaneView;


@interface GeneralPrefController : NSObject <SS_PreferencePaneProtocol, NSAlertDelegate>
{
    IBOutlet WLPrefPaneView *_mainView;
}

- (IBAction)quitBlotter:(id)aSender;

- (IBAction)showMacOSXCalendarSettings:(id)aSender;

@end
