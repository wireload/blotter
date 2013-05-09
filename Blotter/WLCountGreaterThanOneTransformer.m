//
//  WLCountGreaterThanOneTransformer.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 12/02/2011.
//  Copyright 2011 WireLoad, LLC. All rights reserved.
//

#import "WLCountGreaterThanOneTransformer.h"

@implementation WLCountGreaterThanOneTransformer : NSValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

- (id)transformedValue:(id)value
{
    return @([value count] > 1);
}

@end
