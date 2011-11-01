//
//  CalendarsPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"


@class WLPrefPaneView;


/*!
 @abstract  Manages the check property of the items of Calendars in user defaults.
 @see       WLCalendarController
 */
@interface CalendarsPrefController : NSObject <SS_PreferencePaneProtocol, NSTableViewDelegate, NSTableViewDataSource> {
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet NSTableView *_tableView;
    NSMutableArray *_cachedCalCalendars;
}

@property (retain) NSMutableArray *_cachedCalCalendars;

- (NSDictionary *)_calCalendarDictForUID:(NSString *)anUID;

- (void)_setState:(NSNumber *)newState forCalCalendarWithUID:(NSString *)anUID;

/*!
 @abstract  Reloads data if there are only updated calendars.
 */
- (void)_calCalendarsDidChange:(NSNotification *)aNotification;

@end
