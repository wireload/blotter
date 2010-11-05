//
//  GeneralPrefController.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SS_PreferencePaneProtocol.h"


@interface GeneralPrefController : NSObject<SS_PreferencePaneProtocol>
{
    IBOutlet NSView *prefsView;
}

@end
