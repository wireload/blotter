//
//  WLCalendarDateViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WLFoundation/WLFoundation.h>
#import "WLCalendarDateView.h"


/*!
    @brief  Represents date in format relative to current locale.
 */
@interface WLCalendarDateViewController : NSViewController {
    NSCache *_cache;
}

- (WLCalendarDateView *)view;

- (WLSmartClock *)representedObject;

- (void)reloadViewData;


@property (nonatomic, retain) NSDateFormatter *_monthAndYearDateFormatter;

@property (nonatomic, retain) NSDateFormatter *_weekdayDateFormatter;

@end
