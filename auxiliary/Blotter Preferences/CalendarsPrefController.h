//
//  CalendarsPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SS_PreferencePaneProtocol.h"


@interface CalendarsPrefController : NSObject<SS_PreferencePaneProtocol, NSTableViewDelegate>
{
    IBOutlet NSView *mainView;
    IBOutlet NSTableView *tableView;
}

@end
