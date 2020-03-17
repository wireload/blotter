//
//  WLStringToUUIDTransformer.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/12/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import "WLStringToUUIDTransformer.h"


@implementation WLStringToUUIDTransformer

#pragma mark Methods

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return NSUUID.class;
}

- (NSUUID *)transformedValue:(NSString *)aValue
{
    return [[NSUUID alloc] initWithUUIDString:aValue];
}

- (NSString *)reverseTransformedValue:(NSUUID *)aValue
{
    return aValue.UUIDString;
}

@end
