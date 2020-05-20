//
//  WLLayoutPreferencesViewController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>

#import "WLPreferencesViewController.h"
#import "WLLayoutArrangementView.h"


NS_ASSUME_NONNULL_BEGIN

extern NSString * const WLLayoutViewSizeConstraintIdentifier;

/*!
 Preferences view controller for elements layout of the calendar window.
 */
@interface WLLayoutPreferencesViewController : WLPreferencesViewController <NSSplitViewDelegate>

/*!
 Called after the preferences affecting layout change to update appearance and behavior.
 */
- (void)layoutDidChange;

/*!
 Called after split view finishes resize initiated by the user via mouse dragging to update layout preferences.

 @param aSender Split view that was resized by the user.
 */
- (void)userDidChangeLayout:(WLLayoutArrangementView *)aSender;

@end

NS_ASSUME_NONNULL_END
