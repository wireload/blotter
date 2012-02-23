//
//  WLNewEventWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLGlassHudDatePicker.h"


@class WLGlassHudTextView;


@interface WLNewEventWindowController : NSWindowController <NSWindowDelegate, WLGlassHudDatePickerCellDelegate> {
    NSString *title;
    NSString *location;
    BOOL isAllDay;
    NSDate *startDate;
    NSDate *endDate;
    
    
    WLCalendarController *_calendarController;
    NSDate *_datePickerValueBackup;
    IBOutlet WLGlassHudTextView *_titleView;
    id _titleViewObserver;
    IBOutlet WLGlassHudTextView *_locationView;
    IBOutlet NSView *_locationViewContainer;
    id _locationViewObserver;
    IBOutlet WLGlassHudDatePicker *_startDatePicker;
    IBOutlet WLGlassHudDatePicker *_endDatePicker;
    IBOutlet NSButton *_createButton;
}

@property (copy) NSString *title;

@property (copy) NSString *location;

@property BOOL isAllDay;

@property (copy) NSDate *startDate;

@property (copy) NSDate *endDate;

@property (nonatomic, readonly) NSArray *eventCalCalendars;

@property (nonatomic) NSUInteger selectedEventCalCalendarIndex;

@property (nonatomic, readonly) BOOL canCreateEvent;

+ (id)sharedWindowController;

- (id)initWithCalendarController:(WLCalendarController *)aCalendarController;

- (IBAction)setDefaults:(id)aSender;

- (IBAction)create:(id)aSender;


@property (nonatomic, readonly) NSInteger _datePickerElements;

@end
