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
                                  nil];

    [defaults registerDefaults:viewDefaults];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        webContentView = [[WebView alloc] initWithFrame:frame];
        [webContentView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [webContentView setDrawsBackground:NO];
        [webContentView setFrameLoadDelegate:self];
        [webContentView setResourceLoadDelegate:self];
        [self addSubview:webContentView];

        NSString *html = [self calendarHtml];
        NSURL *baseURL = [[NSBundle mainBundle] URLForResource:@"calendar" withExtension:@""];
        // NSLog(@"will display: %@ (base: %@)", html, baseURL);
        [[webContentView mainFrame] loadHTMLString:html baseURL:baseURL];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:@"CalendarAdapterChangedNotification"
                                                   object:[CalendarAdapter sharedCalendarAdapter]];

        fadeController = [[BLFadeController alloc] initWithView:self];
        [fadeController retain];
    }
    return self;
}

- (void)webView:(WebView *)aWebView didFinishLoadForFrame:(WebFrame *)aFrame
{
    if (!initialHtmlLoaded)
    {
        initialHtmlLoaded = YES;
        [self refresh];
    }
}

- (NSDictionary *)calendarInput
{
    NSDictionary *currentCalendar = [[CalendarAdapter sharedCalendarAdapter] currentCalendar];
    [currentCalendar setValue:[NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"FastForward"]] forKey:@"fastForwardNextUp"];
    return currentCalendar;
}

- (NSString *)calendarJson
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

    return json;
}

- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
    // Trap console.log calls.
    [windowScriptObject setValue:self forKey:@"console"];
}

- (void)refresh
{
    NSString *json = [self calendarJson];

    WebScriptObject *scriptObject = [webContentView windowScriptObject];
    [scriptObject callWebScriptMethod:@"updateWhenReady" withArguments:[NSArray arrayWithObject:json]];
}

- (NSString *)calendarHtml
{
	NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"calendar"];

	// Process the template and display the results.

    NSError *error;
    NSStringEncoding enc;
	NSString *html = [NSString stringWithContentsOfFile:templatePath
                                           usedEncoding:&enc
                                                  error:&error];
    if (html == nil)
    {
        html = @"";
        // an error occurred
        NSLog(@"Error reading file at %@\n%@", templatePath, [error localizedFailureReason]);
    }

    return html;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}


/* From http://developer.apple.com/library/mac/#samplecode/CallJS/Listings/SampleController_m.html */

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property
{
    // NSLog(@"%@ received %@ for '%s'", self, NSStringFromSelector(_cmd), property);
    return YES;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    // NSLog(@"%@ received %@ for '%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector));
    return selector != @selector(doOutputToLog:);
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    // NSLog(@"%@ received %@ with sel='%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(sel));
    if (sel == @selector(doOutputToLog:))
        return @"log";
    else
        return nil;
}

- (void)doOutputToLog:(NSString*)theMessage
{
    NSLog(@"Renderer: %@", theMessage);
}


@end
