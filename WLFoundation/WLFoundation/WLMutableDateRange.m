//
//  WLMutableDateRange
//  WLFoundation
//
//  Created by Ilya Kulakov on 23.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLMutableDateRange.h"


@implementation WLMutableDateRange

- (void)unionDateRange:(WLDateRange *)aDateRange
{
    self.startDate = [self.startDate earlierDate:aDateRange.startDate];
    self.endDate = [self.endDate laterDate:aDateRange.endDate];
}

@end