//
//  WLLog
//  WLFoundation
//
//  Created by Ilya Kulakov on 03.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLLog.h"
#import <asl.h>


static void _WLFreeASLClient(aslclient aClient)
{
    asl_close(aClient);
}


@implementation WLLog
{
    dispatch_queue_t loggerQueue;
    aslclient aslClient;
}

- (instancetype)initWithFileDescriptor:(int)aFileDescriptor name:(WLLogName)aName
{
    self = [super init];

    if (self)
    {
        loggerQueue = dispatch_queue_create("net.wireload.WLFoundation.LoggerQueue", 0);

#ifdef DEBUG
        aslClient = asl_open(NULL, aName.UTF8String, ASL_OPT_STDERR);
        asl_set_filter(aslClient, ASL_FILTER_MASK_UPTO(ASL_LEVEL_DEBUG));
#else
        aslClient = asl_open(NULL, aName.UTF8String, 0);
#endif // DEBUG

        dispatch_set_context(loggerQueue, aslClient);
        dispatch_set_finalizer_f(loggerQueue, (dispatch_function_t )_WLFreeASLClient);

        if (aFileDescriptor >= 0)
            asl_add_log_file(aslClient, aFileDescriptor);
    }

    return self;
}

- (instancetype)initWithName:(WLLogName)aName
{
    return [self initWithFileDescriptor:-1 name:aName];
}

- (instancetype)init
{
    return [self initWithFileDescriptor:-1 name:nil];
}

- (instancetype)initWithFile:(NSFileHandle *)aFileHandle name:(NSString *)aName
{
    return [self initWithFileDescriptor:aFileHandle.fileDescriptor name:aName];
}

#pragma mark Methods

+ (instancetype)logForName:(WLLogName)aName
{
    static dispatch_once_t Once;
    static NSMutableDictionary *Logs = nil;
    dispatch_once(&Once, ^
    {
        Logs = [NSMutableDictionary dictionary];
    });

    @synchronized (Logs)
    {
        WLLog *l = Logs[aName];

        if (!l)
        {
            l = [[WLLog alloc] initWithName:aName];
            Logs[aName] = l;
        }
        
        return l;
    }
}

@end


@implementation WLLog (SemiAsynchronous)

NS_INLINE void LogMessage(WLLog *self, int aLevel, NSString *aFormat, va_list args)
{
    NSString *message = [[NSString alloc] initWithFormat:aFormat arguments:args];
    dispatch_async(self->loggerQueue, ^{
        asl_log(self->aslClient, NULL, aLevel, "%s", message.UTF8String);
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


@implementation WLLog (Asynchronous)

NS_INLINE void LogMessageWithMessager(WLLog *self, int aLevel, WLASLLogMessenger aMessager)
{
    dispatch_async(self->loggerQueue, ^{
        asl_log(self->aslClient, NULL, aLevel, "%s", aMessager().UTF8String);
    });
}

- (void)logAlertWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_ALERT, aMessenger);
}

- (void)logCriticalWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_CRIT, aMessenger);
}

- (void)logErrorWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_ERR, aMessenger);
}

- (void)logWarningWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_WARNING, aMessenger);
}

- (void)logNoticeWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_NOTICE, aMessenger);
}

- (void)logInfoWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_INFO, aMessenger);
}

- (void)logDebugWithMessenger:(WLASLLogMessenger)aMessenger
{
    LogMessageWithMessager(self, ASL_LEVEL_DEBUG, aMessenger);
}


@end
