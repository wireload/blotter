//
//  TestWindowController.m
//  Blotter
//
//  Created by Илья Кулаков on 29.06.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "TestWindowController.h"
#import <CalendarStore/CalendarStore.h>



@implementation TestWindowController
@synthesize title;
@synthesize content;

-(void)awakeFromNib {
    [super awakeFromNib];
    controller3 = [[WLCalendarTasksViewController alloc] initWithNibName:nil bundle:nil];
    [controller3 setView:todoView];
    controller3.taskPredicate = [CalCalendarStore taskPredicateWithUncompletedTasks:[[CalCalendarStore defaultCalendarStore] calendars]];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"calendar.title" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO selector:@selector(localizedStandardCompare:)], nil];
    controller3.sortDescriptors = sortDescriptors;
    [controller3 setRepresentedObject:[CalCalendarStore defaultCalendarStore]];
    [controller3 reloadData];
    
    controller4 = [[WLCalendarWeekViewController alloc] initWithNibName:nil bundle:nil];
    [controller4 setRepresentedObject:[self calendarsToDisplay]];
    [controller4 setView:weekView];
    [controller4 bind:@"mode" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"RollingCalendar" options:nil];
    
//    NSPredicate *eventsPred = [CalCalendarStore eventPredicateWithStartDate:[NSDate date]
//                                                                    endDate:[[NSDate date] dateByAddingTimeInterval:3600*24]
//                                                                  calendars:[[CalCalendarStore defaultCalendarStore] calendars]];
//    NSArray *events = [[CalCalendarStore defaultCalendarStore] eventsWithPredicate:eventsPred];
//    events = [events filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isAllDay == NO"]];
//    
//    NSLog(@"%@", [events valueForKey:@"title"]);
//    WLCalendarTimeRulerLayer *layer = [WLCalendarTimeRulerLayer layer];
//    layer.timeRuler = self;
//    [layer setHours:[self timeRulerElements]];
//    [layerTesting setLayer:layer];
//    [layerTesting setWantsLayer:YES];
//    [layer setNeedsDisplay];
}

- (NSArray *)calendarsToDisplay
{
    BOOL displayAllCalendars = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAllCalendars"];
    if (displayAllCalendars)
        return [[CalCalendarStore defaultCalendarStore] calendars];
    else
    {
        NSArray *userCalendars = [[NSUserDefaults standardUserDefaults] arrayForKey:@"Calendars"];
        NSMutableArray *calendars = [NSMutableArray arrayWithCapacity:[userCalendars count]];
        for (NSDictionary *userCalendar in userCalendars)
        {
            if ([[userCalendar objectForKey:@"check"] boolValue])
            {
                CalCalendar *calendar = [[CalCalendarStore defaultCalendarStore] calendarWithUID:[userCalendar objectForKey:@"uid"]];
                if (calendar != nil)
                    [calendars addObject:calendar];
            }
        }
        return calendars;
    }
}

- (NSArray *)timeRulerElements
{
    NSUInteger numberOfColumns = 7;
    NSParameterAssert(numberOfColumns > 0);
    
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    
    // Get the longest day in terms of number of hours
    NSDate *date = nil;
    NSRange hoursRange = NSMakeRange(0, 0);
    for (NSUInteger i=0; i<numberOfColumns; ++i)
    {
        NSDate *columnDate = [NSDate date];
        NSParameterAssert(columnDate != nil);
        NSRange columnRange = [calendar rangeOfUnit:NSHourCalendarUnit inUnit:NSDayCalendarUnit forDate:date];
        if (columnRange.location <= hoursRange.location &&
            columnRange.length > (hoursRange.length + (hoursRange.location - columnRange.location)))
        {
            hoursRange = columnRange;
            date = columnDate;
        }   
    }
    NSParameterAssert(hoursRange.length != 0);
    
    NSDateComponents *components = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                               fromDate:date];
    [components setMinute:0];
    [components setSecond:1];
    
    NSDateFormatter *timeFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [timeFormatter setDateStyle:NSDateFormatterNoStyle];
    [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSMutableArray *elements = [NSMutableArray arrayWithCapacity:hoursRange.length];
    for (NSUInteger i=hoursRange.location; i<hoursRange.length; ++i)
    {
        [components setHour:i];
        date = [calendar dateFromComponents:components];
        [elements addObject:[timeFormatter stringFromDate:date]];
    }
    return elements;
}


- (IBAction)animate:(id)sender
{
    f += 0.5f;
    NSLog(@"%f", f);
    [weekView scrollHour:f];
}

- (IBAction)animate2:(id)sender
{
    f -= 0.5f;
    NSLog(@"%f", f);
    [weekView scrollHour:f];
}

- (IBAction)nextDay:(id)sender
{
    [weekView nextDay];
}

- (IBAction)nextWeek:(id)sender
{
    [weekView nextWeek];
}

@end
