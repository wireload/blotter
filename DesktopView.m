//
//  DesktopView.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 01/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "DesktopView.h"
#import "CalendarAdapter.h"

@implementation DesktopView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        webContentView = [[WebView alloc] initWithFrame:frame];
        [webContentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        NSURL *calendarURL = [[NSBundle mainBundle] URLForResource:@"calendar" withExtension:@"html"];
        [webContentView setMainFrameURL:[calendarURL absoluteString]];
        [webContentView setDrawsBackground:NO];
        [self addSubview:webContentView];

        [self refresh];
    }
    return self;
}

- (void)refresh
{
    NSLog(@"will display: %@", [[CalendarAdapter sharedCalendarAdapter] calendarAsJSON]);
}

@end
