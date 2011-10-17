//
//  BLPositionCalculator.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 24/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "BLCalendarFramer.h"


// Sizes are chosen so that when switching between these 2 modes only week view is disappeard. that is the date, todo and right now vies are visually unchanged.
// @see WLCalendarWindowController
const NSSize BLNarrowMinimumSize = {290, 750};
const NSSize BLNormalMinimumSize = {950, 750};


@implementation BLCalendarFramer

+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin
{
    return [self frameForPosition:aPosition
                          inFrame:frame
                             size:(BLSize)[[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"]
                      scaleFactor:scaleFactor
                           margin:aMargin];
}

+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame size:(BLSize)aCalendarSize
{
    return [self frameForPosition:aPosition
                          inFrame:frame
                             size:aCalendarSize
                      scaleFactor:NSMakePoint(1.0, 1.0)
                           margin:NSMakeSize(14, 14)];
}

+ (NSRect)frameForPosition:(BLPosition)aPosition inFrame:(NSRect)frame size:(BLSize)aCalendarSize scaleFactor:(NSPoint)scaleFactor margin:(NSSize)aMargin
{
    NSSize size;
    switch (aCalendarSize) {
        case BLNarrowSize:
            size = NSMakeSize(BLNarrowMinimumSize.width, MIN(BLNarrowMinimumSize.height, frame.size.height - aMargin.height * 2));
            break;
        case BLFullSize:
            size = NSMakeSize(frame.size.width - aMargin.width * 2, frame.size.height - aMargin.height * 2);
            break;
        default: {
            CGFloat normalWidth = floor(MAX(BLNormalMinimumSize.width, frame.size.width / 2));
            CGFloat normalHeight = floor(MAX(BLNormalMinimumSize.height, frame.size.height / 2));
            size = NSMakeSize(normalWidth, floor(MIN(normalHeight, frame.size.height - aMargin.height * 2)));
            break;
        }
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


    return NSMakeRect(frame.origin.x * scaleFactor.x + px, frame.origin.y * scaleFactor.y + py, size.width, size.height);
}

@end
