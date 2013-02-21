//
//  WLAppDelegate.h
//  Blotter-mini
//
//  Created by Ilya Kulakov on 27.09.12.
//  Copyright (c) 2012 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import <WLFoundation/WLFoundation.h>

@interface WLAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;

@property id<WLCalStore> store;

@property (assign) IBOutlet NSTableView *calendarasTable;

@property (assign) IBOutlet NSDatePicker *fromDatePicker;

@property (assign) IBOutlet NSDatePicker *toDatePicker;

@property (assign) IBOutlet NSArrayController *calendarsController;

@property (assign) IBOutlet NSButton *completedRemindersCheckBox;

@property (assign) IBOutlet NSButton *uncompletedRemindersCheckbox;

@property NSArray *calendars;

@property NSArray *events;

@property NSArray *remidners;

- (IBAction)eventPredicateDidChange:(id)sender;

- (IBAction)reminderPredicateDidChage:(id)sender;

- (void)eventsDidChange:(NSNotification *)aNotification;

@end
