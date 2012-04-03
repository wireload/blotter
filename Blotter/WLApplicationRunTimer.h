//
//  WLApplicationRunTimer.h
//  Blotter
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @discussion    Posted on the main thread.
 */
extern NSString* const WLApplicationRunTimerDidFireNotification;


@interface WLApplicationRunTimer : NSObject
{
    NSString *_delayKey;
    NSString *_elapsedSecondsKey;
    NSString *_isFiredKey;
    uint64_t _start;
    dispatch_queue_t _defaultsAccessQueue;
}

/*!
 @param aDelayKey Specifies a key in NSUserDefaults that points to a double value which represents number before timer should fire.
 @param aIsFiredKey Specifies a key in NSUserDefaults that points to a BOOL value which represents whether timer is already fired.
 @param anElapsedSecondsDefaultsKey Specifies a key in NSUserDefaults that points to a double value which represents elapsed number of seconds.
 */
- (id)initWithDelayDefaultsKey:(NSString *)aDelayKey isFiredDefaultsKey:(NSString *)aIsFiredKey elapsedSecondsDefaultsKey:(NSString *)anElapsedSecondsDefaultsKey;

/*!
 @discussion    Thread safe, async.
 */
- (void)reset;

/*!
 @discussion    Thread safe, async.
 */
- (void)tick;

@end
