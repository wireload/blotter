//
//  WLCalendarsPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLFoundation/WLFoundation.h>
#import "IKPreferencesRepresentation.h"


// FIXME: Rewrite using bindings and array controllers.
@interface WLCalendarsPreferences : WLViewController <IKPreferencesRepresentation, NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView *_eventsTableView;
    IBOutlet NSTableView *_remindersTableView;
}

- (void)calCalendarsDidChange:(NSNotification *)aNotification;

@end
