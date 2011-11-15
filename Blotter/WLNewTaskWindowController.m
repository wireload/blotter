//
//  WLNewTaskWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <CalendarStore/CalendarStore.h>
#import "WLNewTaskWindowController.h"
#import "WLGlassHudTextView.h"


static WLNewTaskWindowController *_sharedInstance;

@implementation WLNewTaskWindowController

- (id)initWithWindow:(NSWindow *)window
{
    if (self = [super initWithWindow:window])
    {
    }
    return self;
}

- (void)dealloc
{
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
    [calendarController release];
    [super dealloc];
}


#pragma mark Properties
@synthesize calendarController;
@dynamic selectedCalCalendarIndex;

- (void)setSelectedCalCalendarIndex:(NSUInteger)newSelectedCalCalendarIndex
{
    [[NSUserDefaults standardUserDefaults] setObject:[[self.calendarController.calCalendars objectAtIndex:newSelectedCalCalendarIndex] uid] forKey:@"uidOfLastSelectedCalendarInTasks"];
}

- (NSUInteger)selectedCalCalendarIndex
{
    NSUInteger selectedCalCalendarIndex = NSNotFound;
    NSString *lastSelectedCalendar = [[NSUserDefaults standardUserDefaults] objectForKey:@"uidOfLastSelectedCalendarInTasks"];
    if (lastSelectedCalendar != nil)
    {
        selectedCalCalendarIndex = [self.calendarController.calCalendars indexOfObjectPassingTest:^BOOL(CalCalendar *calCalendar, NSUInteger idx, BOOL *stop) {
            return [calCalendar.uid isEqualToString:lastSelectedCalendar];
        }];
        if (selectedCalCalendarIndex == NSNotFound)
            selectedCalCalendarIndex = 0;
    }
    else
        selectedCalCalendarIndex = 0;
    return selectedCalCalendarIndex;
}


#pragma mark Methods

+ (id)sharedWindowController
{
    @synchronized (self)
    {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] initWithWindowNibName:@"NewTaskWindow"];
            _sharedInstance.calendarController = [WLCalendarController sharedController];
        }
    }
    return _sharedInstance;
}

- (BOOL)canCreateTask
{
    return ([self.calendarController.calCalendars count] > 0);
}

- (void)reset
{
    [(NSTextView *)_titleView setString:NSLocalizedString(@"New Reminder", @"Default text for title field of the New Reminder panel")];
    [_isDueDate setState:NSOffState];
    [_dueDatePicker setDateValue:[NSDate date]];
    [_priorityPopUp selectItemWithTag:CalPriorityNone];
    [(NSTextView *)_titleView selectAll:self];
}

- (IBAction)create:(id)aSender
{
    CalTask *task = [CalTask task];
    task.title = [(NSTextView *)_titleView string];
    if ([_isDueDate state] == NSOnState)
        task.dueDate = [_dueDatePicker dateValue];
    task.priority = [[_priorityPopUp selectedItem] tag];

    task.calendar = [self.calendarController.calCalendars objectAtIndex:self.selectedCalCalendarIndex];

    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveTask:task error:&error])
        [[self window] orderOut:self];
    else
    {
        NSBeep();
        [NSApp presentError:error];
    }
}


#pragma mark NSWindowController

- (void)windowDidLoad
{
    unichar keyEquiv = NSEnterCharacter;
    NSString *equivString = [NSString stringWithCharacters:&keyEquiv length:1];
    [_createButton setKeyEquivalent:equivString];
    [(NSTextView *)_titleView setFont:[NSFont boldSystemFontOfSize:16]];
    [_dueDatePicker bind:@"hidden"
                toObject:_isDueDate
             withKeyPath:@"cell.state"
                 options:[NSDictionary dictionaryWithObject:[NSValueTransformer valueTransformerForName:NSNegateBooleanTransformerName]
                                                     forKey:NSValueTransformerBindingOption]];

    _titleViewObserver = [[NSNotificationCenter defaultCenter] addObserverForName:WLViewSizeDidChangeNotification
                                                                           object:_titleView
                                                                            queue:nil
                                                                       usingBlock:^(NSNotification *arg1)
    {
        CGFloat heightDiff = [[[arg1 userInfo] objectForKey:WLSizeDiff] sizeValue].height;
        NSRect newWindowFrame = [[self window] frame];
        newWindowFrame.size.height += heightDiff;
        newWindowFrame.origin.y -= heightDiff;

        [[self window] setFrame:newWindowFrame display:YES animate:YES];
    }];
    _titleView.postsSizeChangedNotifications = YES;

    [self reset];
}


#pragma mark NSObject

+ (NSSet *)keyPathsForValuesAffectingCanCreateTask
{
    return [NSSet setWithObject:@"calendarController"];
}

+ (NSSet *)keyPathsForValuesAffectingSelectedCalCalendarIndex
{
    return [NSSet setWithObject:@"calendarController"];
}

@end
