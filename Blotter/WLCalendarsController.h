//
//  WLCalendarsController.h
//  Blotter
//
//  Created by Ilya Kulakov on 06.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalendarStore.h>


extern NSString *WLCalCalendarsDidChangeNotification;

extern NSString *WLCalCalendarsToDisplayDidChangeNotification;


extern NSString *WLChangedCalStoresKey;


@interface WLCalendarsController : NSObject

/*!
    @brief  Instances of objects that adapt WLCalStore protocol which the receiver observes.
 */
@property (readonly) NSArray *calStores;

/*!
    @brief  Autosave key path in the user defaults where the receiver stores it's state.
 */
@property (readonly) NSString *autosaveKeyPath;

@property NSOperationQueuePriority defaultFetchPriority;

/*!
    @brief      Initializes the receiver with aStores and autosave key path.

    @discussion Designated initializer.
 */
- (instancetype)initWithCalStores:(NSArray *)aStores autosaveKeyPath:(NSString *)anAutosaveKeyPath;

- (NSArray *)calCalendarsForStore:(NSObject<WLCalStore> *)aStore;

- (NSArray *)calReminderCalendarsForStore:(NSObject<WLCalStore> *)aStore;

- (NSArray *)calEventCalendarsForStore:(NSObject<WLCalStore> *)aStore;

- (NSArray *)calCalendarsToDisplayForStore:(NSObject<WLCalStore> *)aStore;

- (NSArray *)calReminderCalendarsToDisplayForStore:(NSObject<WLCalStore> *)aStore;

- (NSArray *)calEventCalendarsToDisplayForStore:(NSObject<WLCalStore> *)aStore;

- (BOOL)isUsedToDisplayRemindersCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore;

- (void)setCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayReminders:(BOOL)isUsed;

- (BOOL)isUsedToDisplayEventsCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore;

- (void)setCalCalendarWithUID:(NSString *)anUID ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayEvents:(BOOL)isUsed;

- (void)fetchCalCalendarsForStore:(NSObject <WLCalStore> *)aStore withPriority:(NSOperationQueuePriority)aPriority;

- (void)calStoreDidChange:(NSNotification *)aNotification;

@end
