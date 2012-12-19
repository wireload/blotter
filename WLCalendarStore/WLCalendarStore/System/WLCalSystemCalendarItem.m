//
//  WLCalSystemCalendarItem.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalSystemCalendarItem.h"


@implementation WLCalSystemCalendarItem
@synthesize calendar = _calendar;
@synthesize notes = _notes;
@synthesize URL = _URL;
@synthesize title = _title;
@synthesize lastModifiedDate = _lastModifiedDate;
@synthesize location = _location;
@synthesize itemIdentifier = _itemIdentifier;

#pragma mark NSObject

- (BOOL)isEqual:(WLCalSystemCalendarItem *)anObject
{
    if (![super isEqual:anObject])
        return NO;
    else if (![self.lastModifiedDate isEqual:anObject.lastModifiedDate])
        return NO;
    else if (![self.itemIdentifier isEqual:anObject.itemIdentifier])
        return NO;
    else if (![self.location isEqual:anObject.location])
        return NO;
    else if (![self.URL isEqual:anObject.URL])
        return NO;
    else if (![self.title isEqual:anObject.title])
        return NO;
    else if (![self.notes isEqual:anObject.notes])
        return NO;
    else if (![self.calendar isEqual:anObject.calendar])
        return NO;
    else
        return YES;
}

- (NSUInteger)hash
{
    return [self.itemIdentifier hash];
}

@end