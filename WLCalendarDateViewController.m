//
//  WLCalendarDateViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateViewController.h"


static NSString* const _WLDateFormatterCacheKey = @"dateFormatter";


@implementation WLCalendarDateViewController

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarDateViewController cache"];
    }
    return self;
}

- (void)dealloc
{
    [_cache release];
    [super dealloc];
}


#pragma mark Methods

- (void)updateView
{
    WLCalendarDateView *view = [self view];
    NSDate *date = [[self representedObject] date];
    NSInteger day = [[[[self representedObject] calendar] components:NSDayCalendarUnit fromDate:date] day];
    view.monthDay = [NSString stringWithFormat:@"%ld", day];

    NSLocale *currentLocale = [[[self representedObject] calendar] locale];
    NSDateFormatter *f = self._dateFormatter;
    [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMMMy" options:0 locale:currentLocale]];
    view.monthAndYear = [f stringFromDate:date];

    [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:currentLocale]];
    view.weekday = [f stringFromDate:date];
    [view setNeedsDisplay:YES];
}


#pragma mark Private
@dynamic _dateFormatter;

- (NSDateFormatter *)_dateFormatter
{
    NSDateFormatter *f = [_cache objectForKey:_WLDateFormatterCacheKey];
    if (f == nil) {
        f = [[[NSDateFormatter alloc] init] autorelease];
        [_cache setObject:f forKey:_WLDateFormatterCacheKey];
    }
    return f;
}

- (void)set_dateFormatter:(NSDateFormatter *)newDateFormatter
{
    NSParameterAssert(newDateFormatter == nil);
    [_cache removeObjectForKey:_WLDateFormatterCacheKey];
}


#pragma mark NSViewController

- (void)loadView
{
    WLCalendarDateView *v = [[WLCalendarDateView alloc] init];
    [self setView:v];
    [v release];
    [self updateView];
    [self addObserver:self forKeyPath:@"representedObject.date" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calendar" options:NSKeyValueObservingOptionNew context:NULL];
}

- (WLCalendarDateView *)view
{
    return (WLCalendarDateView *)[super view];
}

- (WLCalendarController *)representedObject
{
    return (WLCalendarController *)[super representedObject];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath hasPrefix:@"representedObject"])
    {
        if ([aKeyPath isEqualToString:@"representedObject.calendar"])
            self._dateFormatter = nil;
        [self updateView];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
