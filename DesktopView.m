//
//  DesktopView.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 01/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <WebKit/WebView.h>
#import <WebKit/WebFrame.h>
#import <WebKit/WebScriptObject.h>

#import <YAJL/YAJL.h>

#import "ICUTemplateMatcher.h"

#import "DesktopView.h"
#import "CalendarAdapter.h"
#import "NSDate-Utilities.h"

@implementation DesktopView

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *viewDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"NO", @"FastForward",
                                  nil, @"DumpJsonPath",
                                  nil, @"DisplayJsonPath",
                                  @"NO", @"AutoFade",
                                  @"60", @"AutoFadeSeconds",
                                  nil];

    [defaults registerDefaults:viewDefaults];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        webContentView = [[WebView alloc] initWithFrame:frame];
        [webContentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [webContentView setDrawsBackground:NO];
        [self addSubview:webContentView];

        templateEngine = [[MGTemplateEngine templateEngine] retain];
        // [engine setDelegate:self];
        [templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:templateEngine]];

        // Set up any needed global variables.
        // [engine setObject:@"Hi there!" forKey:@"hello"];
        NSString *html = [self calendarHtml];
        NSURL *baseURL = [[NSBundle mainBundle] URLForResource:@"calendar" withExtension:@""];
        // NSLog(@"will display: %@ (base: %@)", html, baseURL);
        [[webContentView mainFrame] loadHTMLString:html baseURL:baseURL];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:@"CalendarAdapterChangedNotification"
                                                   object:[CalendarAdapter sharedCalendarAdapter]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:NSApp];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidResignActive:)
                                                     name:NSApplicationDidResignActiveNotification
                                                   object:NSApp];

        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.AutoFade"
                                                                     options:0
                                                                     context:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.AutoFadeSeconds"
                                                                     options:NSKeyValueObservingOptionInitial
                                                                     context:NULL];

    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"values.AutoFade"] || [keyPath isEqualToString:@"values.AutoFadeSeconds"])
    {
        [self createFadeOutTimer];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    [self fadeIn];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    [self createFadeOutTimer];
}

- (void)fadeIn
{
    if ([self alphaValue] < 1.0)
    {
        /*[NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.1];
        [[self animator] setAlphaValue:1.0];
        [NSAnimationContext endGrouping];*/
        [self setAlphaValue:1.0];
    }
}

- (void)fadeOut
{
    if ([self alphaValue] > 0.5)
    {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[self animator] setAlphaValue:0.5];
        [NSAnimationContext endGrouping];
    }
}

- (void)createFadeOutTimer
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldFade = [defaults boolForKey:@"AutoFade"];

    [fadeOutTimer invalidate];
    [fadeOutTimer release];
    fadeOutTimer = nil;

    if (!shouldFade || [NSApp isActive])
    {
        [self fadeIn];
    }
    else
    {
        int fadeSeconds = [defaults integerForKey:@"AutoFadeSeconds"];
        if (fadeSeconds < 1)
            fadeSeconds = 60;

        NSLog(@"Fade out in %d seconds", fadeSeconds);

        fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:fadeSeconds target:self selector:@selector(fadeOut) userInfo:nil repeats:NO];
        [fadeOutTimer retain];
    }
}

- (NSDictionary *)calendarInput
{
    NSDictionary *currentCalendar = [[CalendarAdapter sharedCalendarAdapter] currentCalendar];
    [currentCalendar setValue:[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"FastForward"]] forKey:@"fastForwardNextUp"];
    return currentCalendar;
}

- (void)refresh
{
    NSString *json = [[self calendarInput] yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "];

    WebScriptObject *scriptObject = [webContentView windowScriptObject];
    [scriptObject callWebScriptMethod:@"update" withArguments:[NSArray arrayWithObject:json]];
}

- (NSString *)calendarHtml
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *json = nil;
    NSString *displayJsonPath = [defaults stringForKey:@"DisplayJsonPath"];

    if (displayJsonPath != nil)
    {
        NSLog(@"Loading JSON from %@", displayJsonPath);
        NSError *error;
        NSStringEncoding enc;
        json = [NSString stringWithContentsOfFile:displayJsonPath
                                     usedEncoding:&enc
                                            error:&error];
        if (json == nil)
            // an error occurred
            NSLog(@"Error reading file at %@\n%@",
                  displayJsonPath, [error localizedFailureReason]);
    }
    else
    {
        NSDictionary *currentCalendar = [self calendarInput];
        json = [currentCalendar yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"  "];
    }

    NSString *dumpJsonPath = [defaults stringForKey:@"DumpJsonPath"];
    if (dumpJsonPath != nil)
    {
        NSLog(@"Dumping JSON to %@", dumpJsonPath);
        NSError *error;
        BOOL ok = [json writeToFile:dumpJsonPath
                         atomically:YES
                           encoding:NSUnicodeStringEncoding error:&error];
        if (!ok)
            NSLog(@"Error writing file at %@\n%@",
                  dumpJsonPath, [error localizedFailureReason]);
    }

	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"calendar"];
    // NSLog(@"templatePath: %@", templatePath);

	NSDictionary *variables = [NSDictionary dictionaryWithObjectsAndKeys:
                               json, @"json",
							   nil];

	// Process the template and display the results.
	return [templateEngine processTemplateInFileAtPath:templatePath withVariables:variables];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [templateEngine release];

    [super dealloc];
}

@end
