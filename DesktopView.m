//
//  DesktopView.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 01/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WebKit/WebView.h>
#import <WebKit/WebFrame.h>

#import <YAJL/YAJL.h>

#import "ICUTemplateMatcher.h"

#import "DesktopView.h"
#import "CalendarAdapter.h"
#import "NSDate-Utilities.h"

@implementation DesktopView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        webContentView = [[WebView alloc] initWithFrame:frame];
        [webContentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [webContentView setDrawsBackground:NO];
        [self addSubview:webContentView];

        templateEngine = [MGTemplateEngine templateEngine];
        // [engine setDelegate:self];
        [templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:templateEngine]];

        // Set up any needed global variables.
        // [engine setObject:@"Hi there!" forKey:@"hello"];

        [self refresh];
    }
    return self;
}

- (void)refresh
{
    NSString *html = [self calendarHtml];
    NSURL *baseURL = [[NSBundle mainBundle] URLForResource:@"calendar" withExtension:@""];
    NSLog(@"will display: %@ (base: %@)", html, baseURL);
    [[webContentView mainFrame] loadHTMLString:html baseURL:baseURL];
}

- (NSString *)calendarHtml
{
    NSDictionary *currentCalendar = [[CalendarAdapter sharedCalendarAdapter] currentCalendar];
    [currentCalendar setValue:[NSNumber numberWithBool:NO] forKey:@"fastForwardNextUp"];

    NSString *json = [currentCalendar yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "];

	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"calendar"];
    NSLog(@"templatePath: %@", templatePath);

	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   currentCalendar, @"calendar",
                               json, @"json",
							   nil];

	// Process the template and display the results.
	return [templateEngine processTemplateInFileAtPath:templatePath withVariables:variables];
}

@end
