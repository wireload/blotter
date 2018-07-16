//
//  WLLayoutSplitView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "WLLayoutSplitView.h"


NS_ASSUME_NONNULL_BEGIN


@class WLLayoutSplitView;


@protocol WLLayoutSplitViewDelegate <NSSplitViewDelegate>

@optional

- (void)splitViewWillTrackMouse:(WLLayoutSplitView *)aSplitView;

- (void)splitViewDidTrackMouse:(WLLayoutSplitView *)aSplitView;

@end


@interface WLLayoutSplitView : NSSplitView

@property (nullable, assign) NSObject<WLLayoutSplitViewDelegate> *delegate;

@end


NS_ASSUME_NONNULL_END
