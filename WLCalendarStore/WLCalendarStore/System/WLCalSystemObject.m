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

@end
