//
//  BLPositionerControl.h
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

@interface BLPositionerControl : NSControl {
}

@end
