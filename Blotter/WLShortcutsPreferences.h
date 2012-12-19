//
//  WLShortcutsPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "WLViewController.h"
#import "IKPreferencesRepresentation.h"


@interface WLShortcutsPreferences : WLViewController <IKPreferencesRepresentation /*, SRRecorderControlDelegate */>
{
    IBOutlet SRRecorderControl *_bringToFrontRecroderControl;
    IBOutlet SRRecorderControl *_newEventRecorderControl;
    IBOutlet SRRecorderControl *_newReminderRecorderControl;
    IBOutlet SRRecorderControl *_showNextWeekControl;
    IBOutlet SRRecorderControl *_showCurrentWeekControl;
    IBOutlet SRRecorderControl *_showPrevWeekControl;
}

@end
