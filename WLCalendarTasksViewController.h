//
//  WLCalendarTasksViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 09.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarTasksView.h"


@interface WLCalendarTasksViewController : NSViewController <WLCalendarTasksViewDataSource> {
    NSPredicate *taskPredicate;
    NSArray *sortDescriptors;
    NSMutableArray *_tasks;
}

@property (nonatomic, retain) NSPredicate *taskPredicate;

@property (nonatomic, copy) NSArray *sortDescriptors;

- (WLCalendarTasksView *)view;

/*!
 @discussion    You have to prepare controller (set its properties, representedObject) before calling this method.
 */
- (void)setView:(WLCalendarTasksView *)newView;


- (void)_reloadData;

- (void)_tasksChanged:(NSNotification *)aNotification;

- (void)_preprocessTask:(CalTask *)aTask;

@end
