//
//  GeneralPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class SRRecorderControl;

@class WLPrefPaneView;



@interface GeneralPrefController : NSObject <SS_PreferencePaneProtocol /*, SRRecorderControlDelegate */>
{
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet SRRecorderControl *newEventRecorderControl;
    IBOutlet SRRecorderControl *newTaskRecorderControl;
    IBOutlet SRRecorderControl *showNextWeekControl;
    IBOutlet SRRecorderControl *showPrevWeekControl;
    IBOutlet SRRecorderControl *showCurrentWeekControl;
}

- (IBAction)quitBlotter:(id)sender;

@end
