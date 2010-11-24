//
//  BLPositionCalculator.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 24/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "BLCalendarFramer.h"

const NSSize BLNarrowMinimumSize = {270, 750};
const NSSize BLNormalMinimumSize = {950, 750};

@implementation BLCalendarFramer

+ (NSRect)frameForPosition:(BLPosition)aPosition scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin
{
    return [self frameForPosition:aPosition
                             size:[[NSUserDefaults standardUserDefaults]
                                   stringForKey:@"CalendarSize"]
                      scaleFactor:scaleFactor
                           margin:aMargin];
}

+ (NSRect)frameForPosition:(BLPosition)aPosition size:(NSString *)aCalendarSize
{
    return [self frameForPosition:aPosition size:aCalendarSize scaleFactor:NSMakePoint(1.0, 1.0) margin:NSMakeSize(10, 10)];
}

+ (NSRect)frameForPosition:(BLPosition)aPosition size:(NSString *)aCalendarSize scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin
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
            size = NSMakeSize(frame.size.width - aMargin.width * 2, frame.size.height - aMargin.height * 2);
            break;
        default:
            size = NSMakeSize(MAX(BLNormalMinimumSize.width, frame.size.width / 2), MAX(BLNormalMinimumSize.height, frame.size.height / 2));
            break;
    }

    size.width *= scaleFactor.x;
    size.height *= scaleFactor.y;

    CGFloat px = aMargin.width * scaleFactor.x;
    CGFloat py = aMargin.height * scaleFactor.y;

    if (aPosition == BLPositionTopCenter ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionBottomCenter)
        px = floor(frame.size.width * scaleFactor.x / 2.0 - size.width / 2.0);

    if (aPosition == BLPositionTopRight ||
        aPosition == BLPositionCenterRight ||
        aPosition == BLPositionBottomRight)
        px = frame.size.width * scaleFactor.x - size.width - aMargin.width * scaleFactor.x;

    if (aPosition == BLPositionTopLeft ||
        aPosition == BLPositionTopCenter ||
        aPosition == BLPositionTopRight)
        py = frame.size.height * scaleFactor.y - size.height - aMargin.height * scaleFactor.y;

    if (aPosition == BLPositionCenterLeft ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionCenterRight)
        py = floor(frame.size.height * scaleFactor.y / 2.0 - size.height / 2.0);


    return NSMakeRect(px, py, size.width, size.height);
}

@end
