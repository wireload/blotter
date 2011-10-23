//
//  WLCalendarSizeToArrangementModeTransformer.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 23.10.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLCalendarSizeToArrangementModeTransformer.h"
#import "WLCalendarWindowArrangement.h"


@implementation WLCalendarSizeToArrangementModeTransformer

#pragma mark NSValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (id)transformedValue:(id)aValue
{
    if (aValue != nil)
    {
        switch ([aValue integerValue]) {
            case BLCustomSize:
                return [NSNumber numberWithInteger:WLCalendarWindowPositioningArrangement | WLCalendarWindowResizingArrangement];
            default:
                return [NSNumber numberWithInteger:WLCalendarWindowPositioningArrangement];
        }
    }
    else
        return nil;
}

@end
