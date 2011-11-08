//
//  WLLayoutSplitView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "WLLayoutSplitView.h"


@protocol WLLayoutSplitViewDelegate;


@interface WLLayoutSplitView : NSSplitView

- (NSObject<WLLayoutSplitViewDelegate> *)delegate;

- (void)setDelegate:(NSObject<WLLayoutSplitViewDelegate> *)delegate;

@end


@protocol WLLayoutSplitViewDelegate <NSSplitViewDelegate>

@optional

- (void)splitViewWillTrackMouse:(WLLayoutSplitView *)aSplitView;

- (void)splitViewDidTrackMouse:(WLLayoutSplitView *)aSplitView;

@end
