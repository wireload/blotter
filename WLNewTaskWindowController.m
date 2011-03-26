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


@interface WLNewTaskWindowController (/* Private */)
@property (copy) NSArray *calendars;

@end


static WLNewTaskWindowController *_sharedInstance;

@implementation WLNewTaskWindowController
@synthesize calendars;
@synthesize showDueDatePicker;

+ (BOOL)canCreateTask
{
    return [[[CalCalendarStore defaultCalendarStore] calendars] count];
}

+ (id)sharedWindowController
{
    @synchronized (self)
    {
        if (_sharedInstance == nil) {
            _sharedInstance = [[self alloc] initWithWindowNibName:@"NewTaskWindow"];
        }
    }
    return _sharedInstance;
}

- (id)initWithWindow:(NSWindow *)window
{
    if (self = [super initWithWindow:window])
    {
        self.calendars = [[CalCalendarStore defaultCalendarStore] calendars];
        _calendarsChangedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CalCalendarsChangedExternallyNotification
                                                                                      object:[CalCalendarStore defaultCalendarStore]
                                                                                       queue:nil
                                                                                  usingBlock:^(NSNotification *arg1)
                                     {
                                         self.calendars = [[CalCalendarStore defaultCalendarStore] calendars];
                                     }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_calendarsChangedObserver];
    if (_titleViewObserver != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:_titleViewObserver];
    [calendars release];
    [super dealloc];
}

- (void)windowDidLoad
{
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

- (void)reset
{
    [(NSTextView *)_titleView setString:NSLocalizedString(@"New Task", @"Default text for title field on the New Task panel")];
    [_dueDatePicker setDateValue:[NSDate date]];
    [_priorityPopUp selectItemWithTag:CalPriorityNone];
    self.showDueDatePicker = NO;
    [(NSTextView *)_titleView selectAll:self];
}

- (IBAction)create:(id)aSender
{
    CalTask *task = [CalTask task];
    task.title = [(NSTextView *)_titleView string];
    if (showDueDatePicker)
        task.dueDate = [_dueDatePicker dateValue];
    task.priority = [[_priorityPopUp selectedItem] tag];

    task.calendar = [[_calendarsController selectedObjects] lastObject];

    NSError *error = nil;
    if ([[CalCalendarStore defaultCalendarStore] saveTask:task error:&error])
        [[self window] orderOut:self];
    else
    {
        NSBeep();
        [NSApp presentError:error];
    }
}

@end
