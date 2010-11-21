//
//  DesktopView.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 01/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "ICUTemplateMatcher.h"

#import "DesktopView.h"
#import "CalendarAdapter.h"

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
    NSLog(@"will display: %@", html);
    [[webContentView mainFrame] loadHTMLString:html baseURL:[[NSBundle mainBundle] pathForResource:@"calendar" ofType:@""]];
}

- (NSString *)calendarHtml
{
    NSString *json = [[CalendarAdapter sharedCalendarAdapter] calendarAsJSON];

	// Get path to template.
	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"calendar" ofType:@"html"];

	// Set up some variables for this specific template.
	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSArray arrayWithObjects:
								@"matt", @"iain", @"neil", @"chris", @"steve", nil], @"guys",
							   [NSDictionary dictionaryWithObjectsAndKeys:@"baz", @"bar", nil], @"foo",
                               json, @"json",
							   nil];

	// Process the template and display the results.
	return [templateEngine processTemplateInFileAtPath:templatePath withVariables:variables];
}

@end
