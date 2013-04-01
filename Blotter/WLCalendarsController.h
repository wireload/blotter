//
//  WLCalendarsController.h
//  Blotter
//
//  Created by Ilya Kulakov on 06.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalendarStore.h>


/*
    @brief      The notification which is posted when calendars are changed.

    @discussion User Info dictionary contains changed calendar stores. Observer may access it by using WLChangedCalStoresKey.
                Users should not make any expectations about target thread of this notification.

    @see        WLChangedCalStoresKey
 */
extern NSString *WLCalCalendarsDidChangeNotification;

/*
    @brief      The notification which is posted when calendars to display are changed.

    @discussion User Info dictionary contains changed calendar stores. Observer may access it by using WLChangedCalStoresKey.
                Users should not make any expectations about target thread of this notification.

    @see        WLChangedCalStoresKey
 */
extern NSString *WLCalCalendarsToDisplayDidChangeNotification;


/*!
    @brief  Key used to access changed calendar stores in notification's user info dictionary.
 */
extern NSString *WLChangedCalStoresKey;


/*!
    @brief      Observes given calendar stores and provides facilities to manage displaying of the calendars.

    @discussion Thread Safe.
 */
@interface WLCalendarsController : NSObject

/*!
    @brief      Observed calendar stores.

    @discussion Each instances MUST conform to the WLCalStore protocol.
 */
@property (readonly) NSArray *calStores;

/*!
    @brief  Autosave key path in the user defaults where the receiver stores it's state.
 */
@property (readonly) NSString *autosaveKeyPath;

/*!
    @brief      Initializes the receiver with aStores and autosave key path.

    @discussion Designated initializer.
 */
- (instancetype)initWithCalStores:(NSArray *)aStores autosaveKeyPath:(NSString *)anAutosaveKeyPath;

/*!
    @brief  Returns calendars for aStore.
 */
- (NSArray *)calCalendarsForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Returns reminder calendars for aStore.
 */
- (NSArray *)calReminderCalendarsForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Returns event calendars for aStore.
 */
- (NSArray *)calEventCalendarsForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Returns calendars to display for aStore.
 */
- (NSArray *)calCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Returns reminder calendars to display for aStore.
 */
- (NSArray *)calReminderCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Returns event calendars to display for aStore.
 */
- (NSArray *)calEventCalendarsToDisplayForStore:(NSObject <WLCalStore> *)aStore;

/*!
    @brief  Extracts reminder calendars from aCalCalendars.

    @result An array of reminder calendars or empty array.
 */
- (NSArray *)calReminderCalendarsFromCalCalendars:(NSArray *)aCalCalendars;

/*!
    @brief  Extracts event calendars from aCalCalendars.

    @result An array of event calendars or empty array.
 */
- (NSArray *)calEventCalendarsFromCalCalendars:(NSArray *)aCalCalendars;

/*!
    @brief      Extracts calendars to display from aCalCalendars.

    @result     An array of calendars to display or empty array.
 */
- (NSArray *)calCalendarsToDisplayFromCalCalendars:(NSArray *)aCalCalendars;

/*!
    @brief  Asynchronously fetches calendars from aStore and updates the receiver.
 */
- (void)fetchCalCalendarsForStore:(NSObject <WLCalStore> *)aStore withPriority:(NSOperationQueuePriority)aPriority;

/*!
    @brief  Called when any of observed calendars stores changes.
 */
- (void)calStoreDidChange:(NSNotification *)aNotification;

@end


/*!
    @brief  Methods to configure displaying preferences of calendars.
 */
@interface WLCalendarsController (DisplayingPreferences)

- (BOOL)isCalCalendarUsedToDisplayReminders:(NSObject <WLCalCalendar> *)aCalendar;

- (void)setCalCalendar:(NSObject <WLCalCalendar> *)aCalendar usedToDisplayReminders:(BOOL)isUsed;

- (BOOL)isCalCalendarUsedToDisplayEvents:(NSObject <WLCalCalendar> *)aCalendar;

- (void)setCalCalendar:(NSObject <WLCalCalendar> *)aCalendar usedToDisplayEvents:(BOOL)isUsed;

- (BOOL)isCalCalendarWithIdentifierUsedToDisplayReminders:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore;

- (void)setCalCalendarWithIdentifier:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayReminders:(BOOL)isUsed;

- (BOOL)isCalCalendarWithIdentifierUsedToDisplayEvents:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore;

- (void)setCalCalendarWithIdentifier:(NSString *)anIdentifier ofStore:(NSObject <WLCalStore> *)aStore usedToDisplayEvents:(BOOL)isUsed;

@end


/*!
    @brief      Properties to get calendars from all stores at once.

    @discussion Returned calendars are sorted by 1. title and 2. calendarIdentifier

                All properties are KVO-compliant. Notifications are delivered in the main thread if change is originated by calStore.
                If change is originated by methods of the DisplayingPreferences category, notifications are delivered in the same thread.
 */
@interface WLCalendarsController (CalendarsAccessors)

@property (nonatomic, readonly) NSArray *calCalendars;

@property (nonatomic, readonly) NSArray *calReminderCalendars;

@property (nonatomic, readonly) NSArray *calEventCalendars;

@property (nonatomic, readonly) NSArray *calCalendarsToDisplay;

@property (nonatomic, readonly) NSArray *calReminderCalendarsToDisplay;

@property (nonatomic, readonly) NSArray *calEventCalendarsToDisplay;

@end
