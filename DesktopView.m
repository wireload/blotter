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


@interface DesktopView (/* Private */)

- (NSString *)_monthAndYearOfDateInMilliseconds:(NSNumber *)milliseconds;

- (NSString *)_weekdayOfDateInMilliseconds:(NSNumber *)milliseconds;

@end


@implementation DesktopView

@synthesize initialHtmlLoaded;
@synthesize fadeController;

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

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:NSCurrentLocaleDidChangeNotification
                                                   object:nil];

        fadeController = [[BLFadeController alloc] initWithView:self];
        [fadeController retain];

        dateFormatter = [NSDateFormatter new];
    }
    return self;
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

- (void)refresh
{
    if (!initialHtmlLoaded)
        // refresh will be called automatically when html is loaded.
        return;

    NSString *json = [self calendarJson];

    WebScriptObject *scriptObject = [webContentView windowScriptObject];

    id updateFunction = [scriptObject evaluateWebScript:@"updateWhenReady"];
    if ([[updateFunction description] isEqual:@"undefined"])
    {
        // Even that the frame has been loaded, the updateWhenReady function isn't always ready for some reason,
        // even that it was specifically made to be ready when the frame had loaded.
        NSLog(@"warning: retrying refresh due to unloaded scripts");
        [NSRunLoop cancelPreviousPerformRequestsWithTarget:self];
        [[NSRunLoop currentRunLoop] performSelector:@selector(refresh) target:self argument:nil order:0 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        return;
    }

    id result = [scriptObject callWebScriptMethod:@"updateWhenReady" withArguments:[NSArray arrayWithObject:json]];
    if (![[result description] isEqual:@"1"])
    {
        NSLog(@"error: scheduling of Blotter data update failed.");
        return;
    }

    // Localize strings
    [scriptObject evaluateWebScript:[NSString stringWithFormat:@"$(\"#to-do-box .to-do-string\").text(\"%@\");",
                                              NSLocalizedString(@"To Do", @"Header of To Do items list")]];
    [scriptObject evaluateWebScript:[NSString stringWithFormat:@"$(\"#next-up-box .right-now-string\").text(\"%@\");",
                                              NSLocalizedString(@"Right Now", @"Header of Right Now items list")]];
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
    [dateFormatter release];
    [super dealloc];
}

#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame
{
    [windowObject setValue:self forKey:@"console"];
    [windowObject setValue:self forKey:@"date_formatter"];
}

- (void)webView:(WebView *)aWebView didFinishLoadForFrame:(WebFrame *)aFrame
{
    if (!initialHtmlLoaded)
    {
        initialHtmlLoaded = YES;
        [self refresh];
    }
}

#pragma mark WebScriptObject
/* From http://developer.apple.com/library/mac/#samplecode/CallJS/Listings/SampleController_m.html */

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property
{
    return YES;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    return selector != @selector(doOutputToLog:) &&
           selector != @selector(_monthAndYearOfDateInMilliseconds:) &&
           selector != @selector(_weekdayOfDateInMilliseconds:);
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(doOutputToLog:))
        return @"log";
    else if (sel == @selector(_monthAndYearOfDateInMilliseconds:))
        return @"MonthAndYear";
    else if (sel == @selector(_weekdayOfDateInMilliseconds:))
        return @"Weekday";
    else
        return nil;
}

- (void)doOutputToLog:(NSString*)theMessage
{
    NSLog(@"Renderer: %@", theMessage);
}

- (NSString *)_monthAndYearOfDateInMilliseconds:(NSNumber *)milliseconds {
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"MMMMy" options:0 locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:[NSDate dateWithMillisecondsIntervalSince1970:[milliseconds unsignedLongLongValue]]];
}

- (NSString *)_weekdayOfDateInMilliseconds:(NSNumber *)milliseconds {
    NSString *format = [NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:[NSDate dateWithMillisecondsIntervalSince1970:[milliseconds unsignedLongLongValue]]];
}

@end
