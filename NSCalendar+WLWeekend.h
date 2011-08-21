//
//  NSCalendar+WLWeekend.h
//  Blotter
//
//  Created by Ilya Kulakov on 21.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSCalendar (WLWeekend)

- (BOOL)isWeekend:(NSUInteger)aWeekday;

@end
