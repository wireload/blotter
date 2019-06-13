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


@interface WLShortcutsPreferences : WLViewController <IKPreferencesRepresentation, SRRecorderControlDelegate, SRValidatorDelegate>
{
    __weak IBOutlet SRRecorderControl *_bringToFrontRecroderControl;
    __weak IBOutlet SRRecorderControl *_newEventRecorderControl;
    __weak IBOutlet SRRecorderControl *_newReminderRecorderControl;
    __weak IBOutlet SRRecorderControl *_showNextWeekControl;
    __weak IBOutlet SRRecorderControl *_showCurrentWeekControl;
    __weak IBOutlet SRRecorderControl *_showPrevWeekControl;
}

@end
