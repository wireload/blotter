//
//  WLCalendarRemindersView.h
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLCalendarReminderLayer.h"


@protocol WLCalendarTasksViewDataSource;


/*!
    @brief      Represents list of calendar reminders. Allows to add/remove/move and update items with animation.

    @discussion All animations are implicit. You can group them and disable if needed by calling methods within
                the CATransaction group.
 */
@interface WLCalendarRemindersView : WLLayerHostedView /*<CALayoutManager, CALayerDelegate>*/

@property (assign) id<WLCalendarTasksViewDataSource> dataSource;

- (void)reloadData;

- (void)insertReminderAtIndex:(NSUInteger)anIndex;

- (void)removeReminderAtIndex:(NSUInteger)anIndex;

- (void)updateReminderAtIndex:(NSUInteger)anIndex;

- (void)moveReminderAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex;

- (NSUInteger)numberOfReminders;

@end


@interface WLCalendarRemindersView (Layers)

- (WLCalendarReminderLayer *)makeReminderLayer;

@end


@protocol WLCalendarTasksViewDataSource

- (NSUInteger)numberOfRemindersInRemindersView:(WLCalendarRemindersView *)aTasksView;

- (NSObject<WLCalReminder> *)remindersView:(WLCalendarRemindersView *)aReminderView reminderAtIndex:(NSUInteger)anIndex;

@end
