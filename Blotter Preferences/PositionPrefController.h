//
//  PositionPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"
#import "WLCalendarWindowArrangementView.h"

@class WLPrefPaneView;

@class WLScreensController;


@interface PositionPrefController : NSObject <SS_PreferencePaneProtocol, WLCalendarWindowArrangementDelegate> {
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet WLCalendarWindowArrangementView *_arrangement;
    IBOutlet WLScreensController *_screensController;
    NSSize _defaultFrameSize;
}

- (void)updatePreferredFrameSizeOfPaneView;

@end
