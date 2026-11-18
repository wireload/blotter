//
//  WLCalendarsPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 11/7/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WLPreferencesViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WLCalendarsPreferencesViewController : WLPreferencesViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView *_eventsTableView;
    IBOutlet NSTableView *_remindersTableView;
}

- (void)calCalendarsDidChange:(nullable NSNotification *)aNotification;

@end

NS_ASSUME_NONNULL_END
