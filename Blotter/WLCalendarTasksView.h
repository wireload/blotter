//
//  WLCalendarTasksView.h
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <CalendarStore/CalendarStore.h>
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarTaskLayer.h"


@protocol WLCalendarTasksViewDataSource;


@interface WLCalendarTasksView : WLLayerHostedView /*<CALayoutManager, CALayerDelegate>*/ {
    IBOutlet id<WLCalendarTasksViewDataSource> dataSource;
}

@property (assign) id<WLCalendarTasksViewDataSource> dataSource;

- (void)reloadDataAnimated:(BOOL)isAnimated;

- (void)insertTaskAtIndex:(NSUInteger)anIndex;

- (void)removeTaskAtIndex:(NSUInteger)anIndex;

- (void)updateTaskAtIndex:(NSUInteger)anIndex;

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

- (NSUInteger)numberOfTasks;

@end


@protocol WLCalendarTasksViewDataSource

- (NSUInteger)numberOfTasksInTasksView:(WLCalendarTasksView *)aTasksView;

- (CalTask *)tasksView:(WLCalendarTasksView *)aTasksView taskAtIndex:(NSUInteger)anIndex;

@end


@interface WLCalendarTasksView (Layers)

- (WLCalendarTaskLayer *)makeTaskLayer;

@end
