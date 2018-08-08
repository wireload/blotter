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

/*!
    @brief  Generate persistent distict ID for the current machine.
*/
- (NSString *)makeDistinctIdWithMixpanel:(Mixpanel *)aMixpanel;

@end


@implementation ServiceDelegate

#pragma mark Methods

- (NSString *)makeDistinctIdWithMixpanel:(Mixpanel *)aMixpanel
{
    static NSString* const Salt = @"EXc{8BzFarkm2Ax%Z84?FvkqbrMpaM/q";

    // Protect machine's serial number by salting and hashing it.
    NSString *defaultDistinctId = [aMixpanel performSelector:@selector(defaultDistinctId)];
    NSAssert([defaultDistinctId length] > 0, @"unable to get default distinct ID");
    NSString *saltedDefaultDistinctId = [NSString stringWithFormat:@"%@+%@", defaultDistinctId, Salt];

    NSData *saltedDefaultDistinctIdData = [saltedDefaultDistinctId dataUsingEncoding:NSUTF8StringEncoding];
    u_char distinctIdData[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(saltedDefaultDistinctIdData.bytes, (CC_LONG)saltedDefaultDistinctIdData.length, distinctIdData);

    // Shorten digest.
    static const NSUInteger DISTINCT_ID_LENGTH = 6;
    NSAssert(DISTINCT_ID_LENGTH < CC_SHA256_DIGEST_LENGTH, @"distinct id cannot be larger than digest");
    NSMutableString *distinctId = [NSMutableString stringWithCapacity:DISTINCT_ID_LENGTH * 2];

    for (NSUInteger i = 0; i < DISTINCT_ID_LENGTH; ++i)
        [distinctId appendFormat:@"%02X", distinctIdData[i]];

    return distinctId;
}

#pragma mark NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)aListener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    static NSString* const MixpanelToken = @"ece5b68a45f2721dd049f2e5585478ea";

    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:MixpanelToken];
    [mixpanel identify:[self makeDistinctIdWithMixpanel:mixpanel]];

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
