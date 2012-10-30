//
//  WLASLLog
//  WLFoundation
//
//  Created by Ilya Kulakov on 03.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLASLLog.h"
#import <asl.h>


static void _WLFreeASLClient(aslclient aClient)
{
    asl_close(aClient);
}


@implementation WLASLLog
{
    dispatch_queue_t loggerQueue;
    aslclient aslClient;
}

- (instancetype)initWithFileDescriptor:(int)aFileDescriptor name:(NSString *)aName
{
    self = [super init];

    if (self)
    {
        loggerQueue = dispatch_queue_create("net.wireload.WLFoundation.LoggerQueue", 0);

#ifdef DEBUG
        aslClient = asl_open(NULL, [aName UTF8String], ASL_OPT_STDERR);
#else
        aslClient = asl_open(NULL, [aName UTF8String], 0);
#endif // DEBUG

        dispatch_set_context(loggerQueue, aslClient);
        dispatch_set_finalizer_f(loggerQueue, (dispatch_function_t )_WLFreeASLClient);

        if (aFileDescriptor >= 0)
            asl_add_log_file(aslClient, aFileDescriptor);
    }

    return self;
}

- (instancetype)initWithName:(NSString *)aName
{
    return [self initWithFileDescriptor:-1 name:aName];
}

- (instancetype)init
{
    return [self initWithFileDescriptor:-1 name:nil];
}

- (instancetype)initWithFile:(NSFileHandle *)aFileHandle name:(NSString *)aName
{
    return [self initWithFileDescriptor:[aFileHandle fileDescriptor] name:aName];
}

- (void)dealloc
{
    dispatch_release(loggerQueue);
}


#pragma mark Methods

NS_INLINE void LogMessage(WLASLLog *self, int aLevel, NSString *aFormat, va_list args)
{
    NSString *message = [[NSString alloc] initWithFormat:aFormat arguments:args];
    dispatch_async(self->loggerQueue, ^{
        asl_log(self->aslClient, NULL, aLevel, "%s", [message UTF8String]);
    });
}

- (void)logEmergency:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_EMERG, aFormat, args);
    va_end(args);

}

- (void)logAlert:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_ALERT, aFormat, args);
    va_end(args);
}

- (void)logCritical:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_CRIT, aFormat, args);
    va_end(args);
}

- (void)logError:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_ERR, aFormat, args);
    va_end(args);
}

- (void)logWarning:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_WARNING, aFormat, args);
    va_end(args);
}

- (void)logNotice:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_NOTICE, aFormat, args);
    va_end(args);
}

- (void)logDebug:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_DEBUG, aFormat, args);
    va_end(args);
}

- (void)logInfo:(NSString *)aFormat, ...
{
    va_list args;
    va_start(args, aFormat);
    LogMessage(self, ASL_LEVEL_INFO, aFormat, args);
    va_end(args);
}

@end