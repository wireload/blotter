//
//  WLApplicationPreferences.h
//  Blotter
//
//  Created by Ilya Kulakov on 07.02.13.
//  Copyright (c) 2013 WireLoad. All rights reserved.
//

#import "IKApplicationPreferences.h"


@interface WLApplicationPreferences : IKApplicationPreferences <NSAlertDelegate>

- (void)requestShareAnalyticsConsentIfNeeded;

@end
