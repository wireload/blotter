//
//  BLPositionCalculator.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 24/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    BLNarrowSize    = 0,
    BLNormalSize    = 1,
    BLFullSize      = 2,
};

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

+ (NSRect)frameForPosition:(BLPosition)aPosition size:(NSString *)aCalendarSize;

@end
