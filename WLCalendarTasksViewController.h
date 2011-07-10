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

- (void)reloadData;

- (WLCalendarTasksView *)view;

- (void)setView:(WLCalendarTasksView *)newView;


- (void)_tasksChanged:(NSNotification *)aNotification;

@end
