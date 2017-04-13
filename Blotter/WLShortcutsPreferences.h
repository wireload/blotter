//
//  WLShortcutsPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <WLFoundation/WLFoundation.h>
#import "IKPreferencesRepresentation.h"

@class WLRecorderControl;


@interface WLShortcutsPreferences : WLViewController <IKPreferencesRepresentation, SRRecorderControlDelegate, SRValidatorDelegate>
{
    IBOutlet WLRecorderControl *_bringToFrontRecroderControl;
    IBOutlet WLRecorderControl *_newEventRecorderControl;
    IBOutlet WLRecorderControl *_newReminderRecorderControl;
    IBOutlet WLRecorderControl *_showNextWeekControl;
    IBOutlet WLRecorderControl *_showCurrentWeekControl;
    IBOutlet WLRecorderControl *_showPrevWeekControl;

    SRValidator *_validator;
}

@end
