//
//  main.m
//  Mixpanel
//
//  Created by Ilya Kulakov on 7/9/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mixpanel/Mixpanel.h>

#import "MixpanelProxy.h"


@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end


@implementation ServiceDelegate

#pragma mark NSXPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)aListener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    Mixpanel *mixpanel = [Mixpanel sharedInstanceWithToken:@"ece5b68a45f2721dd049f2e5585478ea"];
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
