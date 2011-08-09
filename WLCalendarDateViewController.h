//
//  WLCalendarDateViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarDateView.h"


@interface WLCalendarDateViewController : NSObject {
    WLCalendarDateView *view;
    NSCalendar *calendar;
    NSDate *date;

    NSCache *_cache;
}

@property (readonly) WLCalendarDateView *view;

@property (retain) NSCalendar *calendar;

@property (copy) NSDate *date;

- (void)updateViewAnimated:(BOOL)isAnimated;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@end
