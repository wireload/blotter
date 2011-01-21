//
//  NSDate-Utilities.h
//  Blotter
//
//  Created by Alexander Ljungberg on 21/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDate (Utilities)

+ (id)dateWithMillisecondsIntervalSince1970:(NSTimeInterval)milliseconds;

+ (NSDate *)midnight;

- (NSDate *)firstMoment;

- (id)JSON;

@end
