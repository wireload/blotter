//
//  WLNewEventWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLGlassHudDatePicker.h"


@class WLGlassHudTextView;

@interface WLNewEventWindowController : NSWindowController <NSWindowDelegate, WLGlassHudDatePickerCellDelegate> {
    IBOutlet WLGlassHudTextView *_titleView;
    id _titleViewObserver;
    IBOutlet WLGlassHudTextView *_locationView;
    IBOutlet NSView *_locationViewContainer;
    id _locationViewObserver;
    IBOutlet NSButton *_isAllDayButton;
    IBOutlet WLGlassHudDatePicker *_startDatePicker;
    IBOutlet WLGlassHudDatePicker *_endDatePicker;
    NSDate *_datePickerValueBackup;

    IBOutlet NSArrayController *_calendarsController;
    id _calendarsChangedObserver;
    NSArray *calendars;
}
@property (copy, readonly) NSArray *calendars;

+ (BOOL)canCreateEvent;

+ (id)sharedWindowController;

- (void)reset;

- (IBAction)create:(id)aSender;

@end
