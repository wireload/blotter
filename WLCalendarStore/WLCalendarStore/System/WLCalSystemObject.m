//
//  WLCalSystemObject.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalSystemObject.h"


@implementation WLCalSystemObject
@synthesize store = _store;

- (instancetype)initWithStore:(id<WLCalStore>)aStore
{
    NSParameterAssert(aStore != nil);

    self = [super init];

    if (self)
    {
        _store = aStore;
    }

    return self;
}

- (instancetype)init
{
    return [self initWithStore:nil];
}


#pragma mark NSObject

- (BOOL)isEqual:(WLCalSystemObject *)anObject
{
    if (self == anObject)
        return YES;
    else if (![anObject isKindOfClass:[self class]])
        return NO;
    else if (self.store != anObject.store)
        return NO;
    else
        return YES;
}

- (NSUInteger)hash
{
    return [self.store hash];
}

@end
