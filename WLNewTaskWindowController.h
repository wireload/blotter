//
//  WLNewTaskWindowController.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLNewTaskWindowController : NSWindowController {
    IBOutlet NSTextField *_titleField;
    IBOutlet NSDatePicker *_dueDatePicker;
    IBOutlet NSPopUpButton *_priorityPopUp;
    
    IBOutlet NSArrayController *_calendarsController;
    id _calendarsChangedObserver;
    NSArray *calendars;
}
@property (copy, readonly) NSArray *calendars;

+ (BOOL)canCreateTask;

+ (id)sharedWindowController;

- (void)reset;

- (IBAction)create:(id)aSender;

@end
