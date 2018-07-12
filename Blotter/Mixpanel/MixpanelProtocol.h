//
//  MixpanelProtocol.h
//  Mixpanel
//
//  Created by Ilya Kulakov on 7/9/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol MixpanelProtocol

- (void)track:(NSString *)anEvent withReply:(nullable dispatch_block_t)aReply;

- (void)track:(NSString *)anEvent withProperties:(nullable NSDictionary *)aProperties andReply:(nullable dispatch_block_t)aReply;

@end

NS_ASSUME_NONNULL_END
