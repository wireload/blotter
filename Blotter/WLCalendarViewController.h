//
//  WLCalendarViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 3/24/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "WLCalendarViewLayout.h"
#import "WLCalendarFloatingWeekEventsViewController.h"
#import "WLCalendarRightNowEventsViewController.h"
#import "WLCalendarRemindersViewController.h"
#import "WLCalendarDateViewController.h"


NS_ASSUME_NONNULL_BEGIN

/*!
 View controller for the content of the main calendar window.

 @discussion
 Content of the view is dynamic. Layout depending on combination of current user preferences,
 window size and current screen. Layout defines which views should be shown which in turn defines
 which controllers are loaded and which properties are observed.
 */
@interface WLCalendarViewController : NSViewController

@property (nonatomic, null_resettable, strong) WLSmartClock *clock;

@property (nullable, readonly) WLCalendarDateViewController *dateViewController;

@property (nullable, readonly) WLCalendarRightNowEventsViewController *rightNowViewController;

@property (nullable, readonly) WLCalendarRemindersViewController *remindersViewController;

@property (nullable, readonly) WLCalendarFloatingWeekEventsViewController *weekViewController;

@property (nonatomic, readonly) BOOL canShowNextWeek;

@property (nonatomic, readonly) BOOL canShowCurrentWeek;

@property (nonatomic, readonly) BOOL canShowPreviousWeek;

@property (nonatomic, readonly) BOOL isCurrentWeekShown;

/*!
 Layout metrics for the controls within given bounds and for given preferences.

 @param aPreferences Preferences for layout. If unspecified, standard user defaults are used.
 */
- (WLCalendarViewLayout *)layoutWithPreferences:(nullable NSDictionary *)aPreferences;

/*!
 Embed a view into box-like view with custom background and title.
 */
- (NSView *)embedView:(NSView *)aContentView inBoxWithTitle:(NSString *)aTitle softEdges:(BOOL)aShouldSoftEdges;

- (IBAction)showNextWeek:(id)aSender;

- (IBAction)showPreviousWeek:(id)aSender;

- (IBAction)showCurrentWeek:(id)aSender;

@end

NS_ASSUME_NONNULL_END
