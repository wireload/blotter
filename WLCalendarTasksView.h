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


@protocol WLCalendarTasksViewDataSource;


@interface WLCalendarTasksView : NSView /*<CALayerDelegate, CALayoutManager>*/ {
    IBOutlet id<WLCalendarTasksViewDataSource> dataSource;
    CALayer *_tasksLayer;
}

@property (nonatomic, assign) id<WLCalendarTasksViewDataSource> dataSource;

- (void)createLayers;

- (void)reloadDataAnimated:(BOOL)isAnimated;

- (void)insertTaskAtIndex:(NSUInteger)anIndex;

- (void)removeTaskAtIndex:(NSUInteger)anIndex;

- (void)updateTaskAtIndex:(NSUInteger)anIndex;

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;


- (CATextLayer *)_setupTaskLayerAtIndex:(NSUInteger)anIndex;

@end


@protocol WLCalendarTasksViewDataSource

- (NSUInteger)numberOfTasksInTasksView:(WLCalendarTasksView *)aTasksView;

- (CalTask *)tasksView:(WLCalendarTasksView *)aTasksView taskAtIndex:(NSUInteger)anIndex;

@end
