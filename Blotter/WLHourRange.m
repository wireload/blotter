//
//  WLHourRange.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.10.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLHourRange.h"


const WLHourRange WLHourRangeZero = {0.0, 0.0};

const WLHourRange WLHourRangeInvalid = {CGFLOAT_MAX, 0.0};


void WLEnumerateHourRange(WLHourRange anHourRange, NSCalendarUnit aUnit, WLHourRangeEnumerationBlock anEnumerateBlock)
{
    switch (aUnit) {
        case NSCalendarUnitHour:
        {
            BOOL shouldStop = NO;
            for (NSUInteger i = 0, size = WLGetNumberOfCalendarUnitsInHourRange(anHourRange, aUnit); i < size && !shouldStop; ++i)
                anEnumerateBlock(aUnit, i, ceil(anHourRange.startHour) + (CGFloat)i, &shouldStop);
            break;
        }
        default:
            return;
    }
}
