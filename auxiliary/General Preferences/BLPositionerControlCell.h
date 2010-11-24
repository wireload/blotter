//
//  BLPositionerControlCell.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BLCalendarFramer.h"

@interface BLPositionerControlCell : NSActionCell {
    NSImage *backgroundImage;

    BOOL    isDragging;
    NSPoint dragStart;
    NSPoint dragOffset;
    int     dragDropPosition;
}

- (NSRect)rectForPosition:(BLPosition)aPosition;
- (NSRect)selectedRect;

@end
