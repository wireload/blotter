//
//  WLNewEventWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLGlassHudDatePicker.h"


@class WLGlassHudTextView;


@interface WLNewEventWindowController : NSWindowController <NSWindowDelegate, WLGlassHudDatePickerCellDelegate>
{
    IBOutlet WLGlassHudTextView *_titleView;
    IBOutlet WLGlassHudTextView *_locationView;
    IBOutlet NSView *_locationViewContainer;
    IBOutlet WLGlassHudDatePicker *_startDatePicker;
    IBOutlet WLGlassHudDatePicker *_endDatePicker;
    IBOutlet NSButton *_createButton;
}

@property (copy) NSString *title;

@property (copy) NSString *location;

@property BOOL isAllDay;

@property (copy) NSDate *startDate;

@property (copy) NSDate *endDate;

@property (copy) NSArray *calCalendars;

@property (nonatomic) NSUInteger selectedCalCalendarIndex;

@property (nonatomic, readonly) BOOL canCreateEvent;

- (IBAction)resetDefaults:(id)aSender;

- (IBAction)create:(id)aSender;

@end


@interface WLNewEventWindowController (Appearance)

@property (nonatomic, readonly) NSDatePickerElementFlags datePickerElements;

@end
