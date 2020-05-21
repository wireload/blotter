//
//  WLCalendarDateViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 3/17/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

@interface WLCalendarDateViewController : NSViewController <NSSplitViewDelegate>

@property (nonatomic, null_resettable, strong) WLSmartClock *clock;

- (void)updateViewContents;

/*!
 Called when calendar changes in a way that must be reflected in the view.
 */
- (void)calendarDidChange;

/*!
 Called when date changes in a way that must be reflected in the view.
 */
- (void)dateDidChange;

@end

NS_ASSUME_NONNULL_END
