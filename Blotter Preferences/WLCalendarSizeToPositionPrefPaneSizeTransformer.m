//
//  WLCalendarSizeToPositionPrefPaneSizeTransformer.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 19.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLCalendarSizeToPositionPrefPaneSizeTransformer.h"
#import "BLCalendarFramer.h"


@implementation WLCalendarSizeToPositionPrefPaneSizeTransformer

- (id)initWithDefaultSize:(NSSize)aDefaultSize
{
    self = [super init];
    if (self != nil)
        defaultSize = aDefaultSize;
    return self;
}


#pragma mark Properties
@synthesize defaultSize;


#pragma mark NSValueTransformer

+ (Class)transformedValueClass
{
    return [NSValue class];
}

- (id)transformedValue:(id)aValue
{
    static const NSSize DoubledPositionControlSize = {.width = 840.0f, .height = 580.0f};
    
    if (aValue != nil)
    {
        switch ([aValue integerValue]) {
            case BLCustomSize:
                return [NSValue valueWithSize:DoubledPositionControlSize];
            BLNarrowSize:
            BLNormalSize:
            BLFullSize:
            default:
                return [NSValue valueWithSize:self.defaultSize];
        }
    }
    else
        return [NSValue valueWithSize:self.defaultSize];
}

@end
