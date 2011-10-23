//
//  BLPositionerControlCell.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowController.h"


/*!
 @discussion    Represented object should be set to any object that responds to CalendarPosition and CustomCalendarFrame keys.
 */
@interface BLPositionerControlCell : NSActionCell {
    NSImage *backgroundImage;
    BLPosition calendarWindowPosition;
    BLSize calendarWindowSize;
    NSRect customFrame;

    BOOL    isDragging;
    NSPoint dragStart;
    NSPoint dragOffset;
    int     dragDropPosition;
}

@property (copy) NSImage *backgroundImage;

@property BLPosition calendarWindowPosition;

@property BLSize calendarWindowSize;

@property NSRect customCalendarWindowFrame;


- (NSRect)rectForPosition:(BLPosition)aPosition;

- (NSRect)selectedRect;

@end
