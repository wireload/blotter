//
//  TestWindowController.h
//  Blotter
//
//  Created by Илья Кулаков on 29.06.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarTasksViewController.h"
#import "WLCalendarWeekViewController.h"
#import "WLCalendarEventLayer.h"
#import "NSColor+CGColor.h"
#import "WLCalendarAllDayEventsLayer.h"
#import "WLCalendarDayEventsLayer.h"
#import "WLCalendarTimeRulerLayer.h"



@interface TestWindowController : NSWindowController <WLCalendarTasksViewDataSource, WLCalendarTimeRuler> {
    NSUInteger i;
    CGFloat f;
    IBOutlet WLCalendarTasksView *todoView;
    NSMutableArray *controller;
    NSArrayController *controller2;
    IBOutlet NSTableView *table;
    NSString *title;
    id content;
    WLCalendarTasksViewController *controller3;
    WLCalendarWeekViewController *controller4;
    IBOutlet WLCalendarWeekView *weekView;
    IBOutlet NSView *layerTesting;
}

- (IBAction)addItemAtMid:(id)sender;

- (IBAction)addItemAtStart:(id)sender;

- (IBAction)addItemAtEnd:(id)sender;

- (IBAction)updateMid:(id)sender;

- (IBAction)animate:(id)sender;

- (IBAction)animate2:(id)sender;

- (IBAction)nextDay:(id)sender;

- (IBAction)nextWeek:(id)sender;

@property (nonatomic, retain) NSString *title;

@property (nonatomic, retain) id content;

-insertObject:(id)obj inControllerAtIndex:(int)idx;

-removeObjectFromControllerAtIndex:(int)idx;

@end
