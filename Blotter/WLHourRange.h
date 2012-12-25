//
//  WLHourRange.h
//  Blotter
//
//  Created by Ilya Kulakov on 10.10.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct
{
    CGFloat startHour;
    CGFloat endHour;
} WLHourRange;


extern const WLHourRange WLHourRangeZero;

extern const WLHourRange WLHourRangeInvalid;


NS_INLINE WLHourRange WLHourRangeMake(CGFloat aStartHour, CGFloat anEndHour)
{
    WLHourRange h = {
        .startHour = aStartHour,
        .endHour = anEndHour
    };
    return h;
}


NS_INLINE BOOL WLHourRangeEqualToHourRange(WLHourRange aHourRange, WLHourRange bHourRange)
{
    return ((aHourRange.startHour == bHourRange.startHour || fabs(aHourRange.startHour - bHourRange.startHour) < FLT_EPSILON) &&
            (aHourRange.endHour == bHourRange.endHour || fabs(aHourRange.endHour - bHourRange.endHour) < FLT_EPSILON));
}


NS_INLINE CGFloat WLHourRangeLength(WLHourRange anHourRange)
{
    return fdim(anHourRange.endHour, anHourRange.startHour);
}


NS_INLINE NSUInteger WLGetNumberOfCalendarUnitsInHourRange(WLHourRange anHourRange, NSCalendarUnit aUnit)
{
    switch (aUnit)
    {
        case NSHourCalendarUnit:
            return (NSUInteger)fdim(floor(anHourRange.endHour), floor(anHourRange.startHour));
        default:
            return NSNotFound;
    }
}


NS_INLINE BOOL WLHourRangeContainsHourRange(WLHourRange aHourRange, WLHourRange bHourRange)
{
    return (aHourRange.startHour <= bHourRange.startHour &&
            aHourRange.endHour >= bHourRange.endHour);
}


NS_INLINE BOOL WLHourRangeContainsHour(WLHourRange anHourRange, CGFloat anHour)
{
    return (anHourRange.startHour - FLT_EPSILON <= anHour &&
            anHourRange.endHour + FLT_EPSILON >= anHour);
}


NS_INLINE NSString * WLStringFromHourRange(WLHourRange anHourRange)
{
    return [NSString stringWithFormat:@"[%.3f, %.3f]", anHourRange.startHour, anHourRange.endHour];
}


typedef void (^WLHourRangeEnumerationBlock)(NSCalendarUnit aUnit, NSUInteger anIndex, CGFloat aMatchedValue, BOOL *aShouldStop);

void WLEnumerateHourRange(WLHourRange anHourRange, NSCalendarUnit aUnit, WLHourRangeEnumerationBlock anEnumerateBlock);
