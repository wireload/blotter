//
//  WLPositioningPreferences.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLFoundation/WLFoundation.h>
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarWindowArrangementView.h"
#import "IKPreferencesRepresentation.h"
#import "WLScreensController.h"


@interface WLPositioningPreferences : WLViewController <IKPreferencesRepresentation, WLCalendarWindowArrangementDelegate>
{
    IBOutlet WLCalendarWindowArrangementView *_arrangement;
    IBOutlet WLScreensController *_screensController;
    NSSize _defaultFrameSize;
}

- (void)updatePreferredFrameSizeOfPaneView;

@end
