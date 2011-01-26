//
//  BLPositionCalculator.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 24/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    BLNarrowSize    = 0,
    BLNormalSize    = 1,
    BLFullSize      = 2,
} BLSize;

typedef enum BLPosition {
    BLPositionTopLeft,
    BLPositionTopCenter,
    BLPositionTopRight,
    BLPositionCenterLeft,
    BLPositionCenterCenter,
    BLPositionCenterRight,
    BLPositionBottomLeft,
    BLPositionBottomCenter,
    BLPositionBottomRight
} BLPosition;

extern NSSize const BLNarrowMinimumSize;
extern NSSize const BLNormalMinimumSize;

@interface BLCalendarFramer : NSObject {

}

+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin;
+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame size:(BLSize)aCalendarSize;
+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame size:(BLSize)aCalendarSize scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin;

@end
