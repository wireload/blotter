//
//  WLApplicationRunTimer.h
//  Blotter
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
    @brief      Notification posted when timer did fire.

    @discussion    Posted on the main thread.
 */
extern NSString* const WLApplicationRunTimerDidFireNotification;


@interface WLApplicationRunTimer : NSObject

@property (readonly, copy) NSString *delayDefaultsKey;

@property (readonly, copy) NSString *elapsedSecondsDefaultsKey;

@property (readonly, copy) NSString *isFiredDefaultsKey;

/*!
    @param  aDelayKey Specifies a key in NSUserDefaults that points to a double value which represents number before timer should fire. CANNOT not be empty.

    @param  anIsFiredKey Specifies a key in NSUserDefaults that points to a BOOL value which represents whether timer is already fired. CANNOT not be empty.

    @param  anElapsedSecondsDefaultsKey Specifies a key in NSUserDefaults that points to a double value which represents elapsed number of seconds. CANNOT not be empty.
 */
- (instancetype)initWithDelayDefaultsKey:(NSString *)aDelayKey isFiredDefaultsKey:(NSString *)anIsFiredKey elapsedSecondsDefaultsKey:(NSString *)anElapsedSecondsDefaultsKey NS_DESIGNATED_INITIALIZER;

/*!
    @brief      Resets timer.

    @discussion Thread safe, async.
 */
- (void)reset;

/*!
    @brief      Increments time and fires notification if elapsed seconds > delay.

    @discussion Thread safe, async.

    @see        WLApplicationRunTimerDidFireNotification
 */
- (void)tick;

@end
