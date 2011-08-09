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
        view = [[WLCalendarDateView alloc] init];
        _cache = [[NSCache alloc] init];
        [_cache setName:@"WLCalendarDateViewController cache"];
    }
    return self;
}

- (void)dealloc
{
    [view release];
    [calendar release];
    [date release];
    [_cache release];
    [super dealloc];
}


#pragma mark Properties
@synthesize view;
@synthesize calendar;
@synthesize date;


#pragma mark Methods

- (void)updateViewAnimated:(BOOL)isAnimated
{
    NSParameterAssert(calendar != nil);
    NSParameterAssert(date != nil);

    if (![view wantsLayer])
        [view setupLayersAnimated:isAnimated];
    [CATransaction begin];
    [CATransaction setDisableActions:!isAnimated];
    NSInteger day = [[calendar components:NSDayCalendarUnit fromDate:date] day];
    view.monthDay = [NSString stringWithFormat:@"%ld", day];

    NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];
    NSDateFormatter *f = self._dateFormatter;
    [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMMMy" options:0 locale:currentLocale]];
    view.monthAndYear = [f stringFromDate:date];

    [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:currentLocale]];
    view.weekday = [f stringFromDate:date];
    [CATransaction commit];
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
#ifdef DEBUG_PERFORMANCE
    else
        NSLog(@"Reuse cache: %@", _WLDateFormatterCacheKey);
#endif
    return f;
}

- (void)set_dateFormatter:(NSDateFormatter *)newDateFormatter
{
    NSParameterAssert(newDateFormatter == nil);
    [_cache removeObjectForKey:_WLDateFormatterCacheKey];
}

@end
