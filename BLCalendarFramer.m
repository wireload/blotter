//
//  BLPositionCalculator.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 24/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "BLCalendarFramer.h"

const NSSize BLNarrowMinimumSize = {270, 750};
const NSSize BLNormalMinimumSize = {801, 750};

@implementation BLCalendarFramer

+ (NSRect)frameForPosition:(BLPosition)aPosition size:(NSString *)aCalendarSize;
{
    NSRect frame = [[NSScreen mainScreen] visibleFrame];

    int sizePrefs = BLNormalSize;
    if ([aCalendarSize isEqualToString:@"Narrow"])
        sizePrefs = BLNarrowSize;
    else if ([aCalendarSize isEqualToString:@"Full"])
        sizePrefs = BLFullSize;

    NSSize size;
    switch (sizePrefs) {
        case BLNarrowSize:
            size = BLNarrowMinimumSize;
            break;
        case BLFullSize:
            size = NSMakeSize(frame.size.width - 20, frame.size.height - 20);
            break;
        default:
            size = NSMakeSize(MAX(BLNormalMinimumSize.width, frame.size.width / 2), MAX(BLNormalMinimumSize.height, frame.size.height / 2));
            break;
    }

    CGFloat px = 10;
    CGFloat py = 10;

    if (aPosition == BLPositionTopCenter ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionBottomCenter)
        px = floor(frame.size.width / 2.0 - size.width / 2.0);

    if (aPosition == BLPositionTopRight ||
        aPosition == BLPositionCenterRight ||
        aPosition == BLPositionBottomRight)
        px = frame.size.width - size.width - 10;

    if (aPosition == BLPositionTopLeft ||
        aPosition == BLPositionTopCenter ||
        aPosition == BLPositionTopRight)
        py = frame.size.height - size.height - 10;

    if (aPosition == BLPositionCenterLeft ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionCenterRight)
        py = floor(frame.size.height / 2.0 - size.height / 2.0);


    return NSMakeRect(px, py, size.width, size.height);
}

@end
