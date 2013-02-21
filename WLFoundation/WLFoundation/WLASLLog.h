//
//  WLASLLog
//  WLFoundation
//
//  Created by Ilya Kulakov on 03.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WLASLLog : NSObject

- (instancetype)initWithName:(NSString *)aName;

- (instancetype)initWithFileDescriptor:(int)aFileDescriptor name:(NSString *)aName;

- (instancetype)initWithFile:(NSFileHandle *)aFileHandle name:(NSString *)aName;

- (void)logEmergency:(NSString *)aFormat, ...;

- (void)logAlert:(NSString *)aFormat, ...;

- (void)logCritical:(NSString *)aFormat, ...;

- (void)logError:(NSString *)aFormat, ...;

- (void)logWarning:(NSString *)aFormat, ...;

- (void)logNotice:(NSString *)aFormat, ...;

- (void)logInfo:(NSString *)aFormat, ...;

- (void)logDebug:(NSString *)aFormat, ...;

@end
