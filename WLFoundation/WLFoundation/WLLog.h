//
//  WLLog
//  WLFoundation
//
//  Created by Ilya Kulakov on 03.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString * WLLogName NS_TYPED_EXTENSIBLE_ENUM;


typedef NSString * (^WLLogMessenger)(void);


/*!
    @brief  Provides logging facility which is supposed to be alternate to NSLog.
            It's os_log (ASL, if not available) and asynchronous and up to x378 faster.

            There are 2 group of methods that represent semi-async and async approaches:

            - Semi-async means that while logging is done in the concurrent queue, the message itself is composed in call place.

            - Async means that both logging and composing is done in the concurrent queue. This approach may be not suitable for
              mutable data, because logging time is undefined and therefore data might change.
 */
@interface WLLog : NSObject

+ (instancetype)logForName:(WLLogName)aName;

- (instancetype)initWithName:(WLLogName)aName;

- (instancetype)initWithFileDescriptor:(int)aFileDescriptor name:(WLLogName)aName NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithFile:(NSFileHandle *)aFileHandle name:(NSString *)aName;

@end


@interface WLLog (SemiAsynchronous)

- (void)logAlert:(NSString *)aFormat, ...;

- (void)logCritical:(NSString *)aFormat, ...;

- (void)logError:(NSString *)aFormat, ...;

- (void)logWarning:(NSString *)aFormat, ...;

- (void)logNotice:(NSString *)aFormat, ...;

- (void)logInfo:(NSString *)aFormat, ...;

- (void)logDebug:(NSString *)aFormat, ...;

@end


@interface WLLog (Asynchronous)

- (void)logAlertWithMessenger:(WLLogMessenger)aMessenger;

- (void)logCriticalWithMessenger:(WLLogMessenger)aMessenger;

- (void)logErrorWithMessenger:(WLLogMessenger)aMessenger;

- (void)logWarningWithMessenger:(WLLogMessenger)aMessenger;

- (void)logNoticeWithMessenger:(WLLogMessenger)aMessenger;

- (void)logInfoWithMessenger:(WLLogMessenger)aMessenger;

- (void)logDebugWithMessenger:(WLLogMessenger)aMessenger;

@end
