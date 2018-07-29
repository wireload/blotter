//
//  main.m
//  Mixpanel
//
//  Created by Ilya Kulakov on 7/9/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mixpanel/Mixpanel.h>
#import <CommonCrypto/CommonCrypto.h>

#import "MixpanelProxy.h"


@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end


@implementation ServiceDelegate

#pragma mark NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)aListener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"ece5b68a45f2721dd049f2e5585478ea"];

    // Distinct ID is a serial number of the machine. We should not expsoe it.
    NSData *defaultDistinctId = [[mixpanel performSelector:@selector(defaultDistinctId)] dataUsingEncoding:NSUTF8StringEncoding];
    NSAssert([defaultDistinctId length] > 0, @"unable to get default distinct ID");
    u_char distinctIdData[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(defaultDistinctId.bytes, (CC_LONG)defaultDistinctId.length, distinctIdData);

    // Shorten digest.
    static const NSUInteger DISTINCT_ID_LENGTH = 6;
    NSAssert(DISTINCT_ID_LENGTH < CC_SHA256_DIGEST_LENGTH, @"distinct id cannot be larger than digest");
    NSMutableString *distinctID = [NSMutableString stringWithCapacity:DISTINCT_ID_LENGTH * 2];

    for (NSUInteger i = 0; i < DISTINCT_ID_LENGTH; ++i)
        [distinctID appendFormat:@"%02X", distinctIdData[i]];

    [mixpanel identify:distinctID];

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MixpanelProtocol)];
    newConnection.exportedObject = [[MixpanelProxy alloc] initWithMixpanel:mixpanel];
    [newConnection resume];

    return YES;
}

@end


int main(int argc, const char *argv[])
{
    ServiceDelegate *delegate = [ServiceDelegate new];

    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;

    [listener resume];
    return 0;
}
