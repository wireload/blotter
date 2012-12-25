//
//  WLCalEventsPredicate.h
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 05.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>


@interface WLCalEventsPredicate : NSObject <NSCopying>

@property (readonly) NSArray *calendarIdentifiers;

@property (readonly) WLDateRange *dateRange;

- (instancetype)initWithDateRange:(WLDateRange *)aDateRange calendarIdentifiers:(NSArray *)aCalendarIdentifiers;

+ (instancetype)predicateWithDateRange:(WLDateRange *)aDateRange calendarIdentifiers:(NSArray *)aCalendarIdentifiers;

@end
