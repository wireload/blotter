//
//  MixpanelProxy.h
//  Mixpanel
//
//  Created by Ilya Kulakov on 7/9/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MixpanelProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@interface MixpanelProxy : NSObject <MixpanelProtocol>

- (instancetype)initWithMixpanel:(Mixpanel *)aMixpanel NS_DESIGNATED_INITIALIZER;

- (void)performBlock:(dispatch_block_t)aBlock withReply:(nullable dispatch_block_t)aReply;

@end

NS_ASSUME_NONNULL_END
