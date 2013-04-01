//
//  WLNewReminderWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLCalendarStore/WLCalendarStore.h>


@class WLGlassHudTextView;


@interface WLNewReminderWindowController : NSWindowController
{
    IBOutlet WLGlassHudTextView *_titleView;
    IBOutlet NSButton *_createButton;
}

@property BOOL isDueDate;

@property (copy) NSDate *dueDate;

@property (copy) NSString *title;

@property NSInteger priority;

@property (nonatomic, copy) NSArray *calCalendars;

@property (nonatomic) NSUInteger selectedCalCalendarIndex;

@property (nonatomic, readonly) BOOL canCreateReminder;

- (IBAction)resetDefaults:(id)aSender;

- (IBAction)create:(id)aSender;

@end
