//
//  GeneralPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SS_PreferencePaneProtocol.h"


@class SRRecorderControl;


@interface GeneralPrefController : NSObject<SS_PreferencePaneProtocol /*, SRRecorderControlDelegate */>
{
    IBOutlet NSView *prefsView;
    IBOutlet SRRecorderControl *newEventRecorderControl;
    IBOutlet SRRecorderControl *newTaskRecorderControl;
}

- (IBAction)quitBlotter:(id)sender;

@end
