//
//  WLLayoutView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WLLayoutViewTag)
{
    WLLayoutViewTagDate = 1,
    WLLayoutViewTagTasks,
    WLLayoutViewTagAllDay,
    WLLayoutViewTagDay,
    WLLayoutViewTagRightNow,
    WLLayoutViewTagInfo,
    WLLayoutViewTagWeek
};

#pragma mark - WLLayoutSplitView

@class WLLayoutArrangementView;


@protocol WLLayoutArrangementViewDelegate <NSSplitViewDelegate>

@optional

- (void)splitViewWillTrackMouse:(WLLayoutArrangementView *)aSplitView;

- (void)splitViewDidTrackMouse:(WLLayoutArrangementView *)aSplitView;

@end


@interface WLLayoutArrangementView : NSSplitView

@property (nullable, weak) id<WLLayoutArrangementViewDelegate> delegate;

@end


@interface WLLayoutWeekSplitView : WLLayoutArrangementView
@end

#pragma mark - WLLayoutView

@interface WLLayoutView : NSView
@end


@interface WLLayoutAllDayView : WLLayoutView
@end


@interface WLLayoutDateView : WLLayoutView
@end


@interface WLLayoutDayView : WLLayoutView
@end


@interface WLLayoutInfoSplitView : WLLayoutArrangementView
@end


@interface WLLayoutRightNowView : WLLayoutView
@end


@interface WLLayoutTasksView : WLLayoutView
@end

NS_ASSUME_NONNULL_END
