//
//  WLCalendarWindowController.h
//  Blotter
//
//  Created by Илья Кулаков on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindow.h"
#import "WLCalendarWeekViewController.h"
#import "WLCalendarTasksViewController.h"
#import "BLCalendarFramer.h"


@interface WLCalendarWindowController : NSWindowController <NSWindowDelegate> {
    BLSize windowSize;
    BLPosition windowPosition;
    NSNumber *windowScreenIdentifier;

    WLCalendarWeekViewController *_weekViewController;
    WLCalendarTasksViewController *_tasksViewController;

    BOOL _isWindowShowed;
}

@property (nonatomic) BLSize windowSize;

@property (nonatomic) BLPosition windowPosition;

@property (nonatomic, copy) NSNumber *windowScreenIdentifier;

- (id)initWithWindow:(WLCalendarWindow *)aWindow;

- (WLCalendarWindow *)window;

- (void)setWindow:(WLCalendarWindow *)newWindow;

- (NSArray *)calendarsToDisplay;


- (void)_updateFrame;

- (void)_applyWindowSizeToViews;

- (void)_applyNarrowSizeToViews;

- (void)_applyNormalSizeToViews;

- (void)_applyFullSizeToViews;

@end
