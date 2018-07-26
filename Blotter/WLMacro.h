//
//  WLMacro.h
//  Blotter
//
//  Created by Ilya Kulakov on 7/26/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IS_EQ_CGFLOAT(a, b) (BOOL)(fabs((b) - (a)) < DBL_EPSILON)

#define IS_LESS_OR_EQ_CGFLOAT(a, b) (BOOL)((a) <= (b) || IS_EQ_CGFLOAT(a, b))

#define IS_LESS_CGFLOAT(a, b) (BOOL)((a) < (b) && !IS_EQ_CGFLOAT(a, b))


// From http://kuoi.com/~kamikaze/read.php?id=158
#ifdef DEBUG
// DLOG takes a format argument and 0 or more args:
// DLOG(@"");
// DLOG(@"%d", x);
#define DLOG(fmt, ...) NSLog(@"%s: " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define DLOG(...)
#endif

// Simple timer.
#ifdef DEBUG
#define BEGIN_TIMING()  NSTimeInterval __begin_timing_start = [NSDate timeIntervalSinceReferenceDate];
#define END_TIMING(msg) DLOG(@"%@: %dms", msg, (int) (([NSDate timeIntervalSinceReferenceDate] - __begin_timing_start) * 1000.0));
#else
#define BEGIN_TIMING()
#define END_TIMING(msg)
#endif
