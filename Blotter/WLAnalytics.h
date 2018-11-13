//
//  WLAnalytics.h
//  Blotter
//
//  Created by Ilya Kulakov on 11/12/18.
//  Copyright 2018 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


extern const CGFloat WLAnalyticsDefaultSampleRate;


NS_ASSUME_NONNULL_BEGIN

@interface WLAnalytics : NSObject

@property(class, readonly) WLAnalytics *sharedAnalytics;

/*!
    @param aSampleRate Sample rate for the action events.
 */
- (instancetype)initWithSampleRate:(CGFloat)aSampleRate;

- (NSXPCConnection *)makeConnection;

/*!
    Parse app-level properties for reporting.
 */
- (NSDictionary *)parseAppProperties;

/*!
    Parse application's purchase receipt for analytics.
 */
- (NSDictionary *)parseReceipt;

/*!
    @brief Report the Launched event to Mixpanel.

    @discussion Reports only once per application lifetime and only if user gave consent.

    @see WLShareAnalytics
 */
- (void)reportLaunchedToMixpanelIfNeeded;

/*!
    @brief Report the Daily event to Mixpanel.

    @discussion Reports daily (if system allows) only if user gave consent.

    @see WLShareAnalytics
 */
- (void)reportDailyToMixpanelIfNeeded;

/*!
    @brief Report named action event to Mixpanel.

    @see WLShareAnalytics
 */
- (void)reportAction:(NSString *)anActionName;

@end

NS_ASSUME_NONNULL_END
