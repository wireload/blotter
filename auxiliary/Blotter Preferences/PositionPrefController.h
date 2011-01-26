//
//  PositionPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SS_PreferencePaneProtocol.h"
#import "BLPositionerControl.h"

@interface PositionPrefController : NSObject<SS_PreferencePaneProtocol>
{
    IBOutlet NSView *mainView;
    IBOutlet BLPositionerControl *positionView;
}

@end
