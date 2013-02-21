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
    NSArray *sortDescriptors;
    NSMutableArray *_tasks;
    BOOL _isViewLoaded;
}

@property (nonatomic, copy) NSArray *sortDescriptors;

- (WLCalendarTasksView *)view;

/*!
 @abstract Fetches tasks and reload data of view without care of current state.
 */
- (void)fetchTasksAndReloadViewDataAnimated:(BOOL)isAnimated;

/*!
 @abstract Inserts/updates/deletes tasks of the view if there are only updated tasks.
 */
- (void)_calTasksDidChange:(NSNotification *)aNotification;

@end


@interface CalTask (WLCalendarTasksViewController)

/*!
 @abstract Fixes priority and due date for correct sorting.
 */
- (void)WL_fixPriorityAndDueDate;

@end
