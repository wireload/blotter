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


@interface WLCalendarTasksView : NSView /*<CALayoutManager>*/ {
    IBOutlet id<WLCalendarTasksViewDataSource> dataSource;
    CALayer *_tasksLayer;
}

@property (nonatomic, assign) id<WLCalendarTasksViewDataSource> dataSource;

- (void)setupLayers;

- (CATextLayer *)newTaskLayerAtIndex:(NSUInteger)anIndex;

- (void)reloadData;


- (void)insertTaskAtIndex:(NSUInteger)anIndex;

- (void)removeTaskAtIndex:(NSUInteger)anIndex;

- (void)updateTaskAtIndex:(NSUInteger)anIndex;

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

@end


@protocol WLCalendarTasksViewDataSource

- (NSUInteger)numberOfTasks;

- (CalTask *)taskAtIndex:(NSUInteger)anIndex;

@end
