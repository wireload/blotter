//
//  PositionPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"
#import "WLCalendarWindowArrangement.h"

@class WLPrefPaneView;


@interface PositionPrefController : NSObject <SS_PreferencePaneProtocol, WLCalendarWindowArrangementDelegate> {
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet WLCalendarWindowArrangement *_positionView;
    IBOutlet NSArrayController *_screensController;
}

@end
