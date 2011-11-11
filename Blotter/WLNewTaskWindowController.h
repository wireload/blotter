//
//  WLNewTaskWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLGlassHudTextView;


@interface WLNewTaskWindowController : NSWindowController {
    WLCalendarController *calendarController;

    IBOutlet WLGlassHudTextView *_titleView;
    id _titleViewObserver;
    IBOutlet NSButton *_isDueDate;
    IBOutlet NSDatePicker *_dueDatePicker;
    IBOutlet NSPopUpButton *_priorityPopUp;
    IBOutlet NSButton *_createButton;
}

@property (retain) WLCalendarController *calendarController;

@property (nonatomic) NSUInteger selectedCalCalendarIndex;

+ (id)sharedWindowController;

- (void)reset;

- (IBAction)create:(id)aSender;

- (BOOL)canCreateTask;

@end
