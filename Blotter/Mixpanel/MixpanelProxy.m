//
//  MixpanelProxy.m
//  Mixpanel
//
//  Created by Ilya Kulakov on 7/9/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import <Mixpanel/Mixpanel.h>

#import "MixpanelProxy.h"


@implementation MixpanelProxy
{
    Mixpanel *_mixpanel;
}

- (instancetype)init
{
    return [self initWithMixpanel:[Mixpanel sharedInstance]];
}

- (instancetype)initWithMixpanel:(Mixpanel *)aMixpanel
{
    if (self = [super init])
    {
        _mixpanel = aMixpanel;
    }

    return self;
}


#pragma mark Methods

- (void)performBlock:(dispatch_block_t)aBlock withReply:(dispatch_block_t)aReply;
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), dispatch_block_create(DISPATCH_BLOCK_DETACHED, ^{
        xpc_transaction_begin();
        aBlock();

        [[Mixpanel sharedInstance] flushWithCompletion:^{
            aReply();
            xpc_transaction_end();
        }];
    }));
}


#pragma mark MixpanelProtocol

- (void)track:(NSString *)anEvent withReply:(dispatch_block_t)aReply;
{
    [self track:anEvent withProperties:nil andReply:aReply];
}

- (void)track:(NSString *)anEvent withProperties:(NSDictionary *)aProperties andReply:(dispatch_block_t)aReply;
{
    [self performBlock:^{ [self->_mixpanel track:anEvent properties:aProperties]; } withReply:aReply];
}

- (void)peopleSet:(NSDictionary *)aProperties withReply:(dispatch_block_t)aReply
{
    [self performBlock:^{ [self->_mixpanel.people set:aProperties]; } withReply:aReply];
}

@end
