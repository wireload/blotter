//
//  WLNewEventWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLGlassHudDatePicker.h"
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>


@class WLGlassHudTextView;


@interface WLNewEventWindowController : NSWindowController <NSWindowDelegate, WLGlassHudDatePickerCellDelegate> {
    WLCalendarController *calendarController;

    IBOutlet WLGlassHudTextView *_titleView;
    id _titleViewObserver;
    IBOutlet WLGlassHudTextView *_locationView;
    IBOutlet NSView *_locationViewContainer;
    id _locationViewObserver;
    IBOutlet NSButton *_isAllDayButton;
    IBOutlet WLGlassHudDatePicker *_startDatePicker;
    IBOutlet WLGlassHudDatePicker *_endDatePicker;
    NSDate *_datePickerValueBackup;
    IBOutlet NSButton *_createButton;
}

@property (retain) WLCalendarController *calendarController;

@property (nonatomic) NSUInteger selectedCalCalendarIndex;

+ (id)sharedWindowController;

- (BOOL)canCreateEvent;

- (void)reset;

- (IBAction)create:(id)aSender;

@end
