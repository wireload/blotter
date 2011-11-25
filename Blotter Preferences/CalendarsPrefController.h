//
//  CalendarsPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLPrefPaneView;


/*!
 @see       WLCalendarController
 */
@interface CalendarsPrefController : NSObject <SS_PreferencePaneProtocol, NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet NSTableView *_eventsTableView;
    IBOutlet NSTableView *_remindersTableView;
}

@end
