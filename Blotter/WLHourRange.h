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


NS_INLINE BOOL WLHourRangeEqualToHourRange(WLHourRange l, WLHourRange r)
{
    return (l.startHour == r.startHour || fabsf(l.startHour - r.startHour) < FLT_EPSILON) &&
    (l.endHour == r.endHour || fabsf(l.endHour - r.endHour) < FLT_EPSILON);
}


NS_INLINE CGFloat WLHourRangeLength(WLHourRange range)
{
    return (range.endHour - range.startHour);
}