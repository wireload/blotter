//
//  WLNewTaskWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarController.h"


@class WLGlassHudTextView;


@interface WLNewTaskWindowController : NSWindowController {
    BOOL isDueDate;
    NSDate *dueDate;
    NSString *title;
    NSInteger priority;

    WLCalendarController *_calendarController;
    IBOutlet WLGlassHudTextView *_titleView;
    id _titleViewObserver;
    IBOutlet NSButton *_createButton;
}

@property BOOL isDueDate;

@property (copy) NSDate *dueDate;

@property (copy) NSString *title;

@property NSInteger priority;

@property (nonatomic, readonly) NSArray *taskCalCalendars;

@property (nonatomic) NSUInteger selectedTaskCalCalendarIndex;

@property (nonatomic, readonly) BOOL canCreateTask;

+ (id)sharedWindowController;

- (id)initWithCalendarController:(WLCalendarController *)aCalendarController;

- (IBAction)setDefaults:(id)aSender;

- (IBAction)create:(id)aSender;

@end
