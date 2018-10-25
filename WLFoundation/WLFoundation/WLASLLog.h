//
//  WLASLLog
//  WLFoundation
//
//  Created by Ilya Kulakov on 03.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NSString * (^WLASLLogMessenger)(void);


/*!
    @brief  Provides logging facility which is supposed to be alternate to NSLog.
            It's ASL-based, and asynchronous and up to x378 faster.

            There are 2 group of methods that represent semi-async and async approaches:

            - Semi-async means that while logging is done in the concurrent queue, the message itself is composed in call place.

            - Async means that both logging and composing is done in the concurrent queue. This approach may be not suitable for
              mutable data, because logging time is undefined and therefore data might change.
 */
@interface WLASLLog : NSObject

- (instancetype)initWithName:(NSString *)aName;

- (instancetype)initWithFileDescriptor:(int)aFileDescriptor name:(NSString *)aName NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFile:(NSFileHandle *)aFileHandle name:(NSString *)aName;

+ (instancetype)logForName:(NSString *)aName;

@end


@interface WLASLLog (SemiAsynchronous)

- (void)logAlert:(NSString *)aFormat, ...;

- (void)logCritical:(NSString *)aFormat, ...;

- (void)logError:(NSString *)aFormat, ...;

- (void)logWarning:(NSString *)aFormat, ...;

- (void)logNotice:(NSString *)aFormat, ...;

- (void)logInfo:(NSString *)aFormat, ...;

- (void)logDebug:(NSString *)aFormat, ...;

@end


@interface WLASLLog (Asynchronous)

- (void)logAlertWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logCriticalWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logErrorWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logWarningWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logNoticeWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logInfoWithMessenger:(WLASLLogMessenger)aMessenger;

- (void)logDebugWithMessenger:(WLASLLogMessenger)aMessenger;

@end
