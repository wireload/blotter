//
//  ShortcutsPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLPrefPaneView;

@class SRRecorderControl;


@interface ShortcutsPrefController : NSObject <SS_PreferencePaneProtocol /*, SRRecorderControlDelegate */>
{
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet SRRecorderControl *_bringToFrontRecroderControl;
    IBOutlet SRRecorderControl *_newEventRecorderControl;
    IBOutlet SRRecorderControl *_newReminderRecorderControl;
    IBOutlet SRRecorderControl *_showNextWeekControl;
    IBOutlet SRRecorderControl *_showCurrentWeekControl;
    IBOutlet SRRecorderControl *_showPrevWeekControl;
}

@end
