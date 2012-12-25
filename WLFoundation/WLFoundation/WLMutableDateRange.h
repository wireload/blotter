//
//  WLMutableDateRange
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLDateRange.h>


@interface WLMutableDateRange : WLDateRange

@property (copy) NSDate *startDate;

@property (copy) NSDate *endDate;

- (void)unionDateRange:(WLDateRange *)aDateRange;

@end
