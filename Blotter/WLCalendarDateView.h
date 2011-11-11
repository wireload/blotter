//
//  WLCalendarDateView.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLCalendarDateView : NSView {
    NSString *monthDay;
    NSString *monthAndYear;
    NSString *weekday;
}

@property (nonatomic, copy) NSString *monthDay;

@property (nonatomic, copy) NSString *monthAndYear;

@property (nonatomic, copy) NSString *weekday;

@end
