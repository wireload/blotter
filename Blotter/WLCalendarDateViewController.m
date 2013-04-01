//
//  WLCalendarDateViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarDateViewController.h"


static NSString* const _WLMonthAndYearDateFormatterCacheKey = @"monthAndYearDateFormatter";

static NSString* const _WLWeekdayDateFormatterCacheKey = @"weekdayDateFormatter";


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
    [self removeObserver:self forKeyPath:@"representedObject.date"];
    [self removeObserver:self forKeyPath:@"representedObject.calendar.locale"];
    [super dealloc];
}


#pragma mark Methods

- (void)reloadViewData
{
    WLCalendarDateView *view = [self view];
    NSDate *date = [[self representedObject] date];
    NSInteger day = [[[[self representedObject] calendar] components:NSDayCalendarUnit fromDate:date] day];
    view.monthDay = [NSString stringWithFormat:@"%ld", day];
    view.monthAndYear = [self._monthAndYearDateFormatter stringFromDate:date];
    view.weekday = [self._weekdayDateFormatter stringFromDate:date];
    [view setNeedsDisplay:YES];
}


#pragma mark Private
@dynamic _monthAndYearDateFormatter;
@dynamic _weekdayDateFormatter;

- (NSDateFormatter *)_monthAndYearDateFormatter
{
    NSDateFormatter *f = [[[_cache objectForKey:_WLMonthAndYearDateFormatterCacheKey] retain] autorelease];
    if (f == nil) {
        f = [[[NSDateFormatter alloc] init] autorelease];
        [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMMMy" options:0 locale:[[self representedObject].calendar locale]]];
        [_cache setObject:f forKey:_WLMonthAndYearDateFormatterCacheKey];
    }
    return f;
}

- (void)set_monthAndYearDateFormatter:(NSDateFormatter *)newDateFormatter
{
    NSParameterAssert(newDateFormatter == nil);
    [_cache removeObjectForKey:_WLMonthAndYearDateFormatterCacheKey];
}

- (NSDateFormatter *)_weekdayDateFormatter
{
    NSDateFormatter *f = [[[_cache objectForKey:_WLWeekdayDateFormatterCacheKey] retain] autorelease];
    if (f == nil) {
        f = [[[NSDateFormatter alloc] init] autorelease];
        [f setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"cccc" options:0 locale:[[self representedObject].calendar locale]]];
        [_cache setObject:f forKey:_WLWeekdayDateFormatterCacheKey];
    }
    return f;
}

- (void)set_weekdayDateFormatter:(NSDateFormatter *)newDateFormatter
{
    NSParameterAssert(newDateFormatter == nil);
    [_cache removeObjectForKey:_WLWeekdayDateFormatterCacheKey];
}


#pragma mark NSViewController

- (void)loadView
{
    WLCalendarDateView *v = [[WLCalendarDateView alloc] init];
    [self setView:v];
    [v release];
    [self reloadViewData];
    [self addObserver:self forKeyPath:@"representedObject.date" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"representedObject.calendar.locale" options:NSKeyValueObservingOptionNew context:NULL];
}

- (WLCalendarDateView *)view
{
    return (WLCalendarDateView *)[super view];
}

- (WLSmartClock *)representedObject
{
    return (WLSmartClock *)[super representedObject];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"representedObject.calendar.locale"])
    {
        self._monthAndYearDateFormatter = nil;
        self._weekdayDateFormatter = nil;
#ifdef DEBUG
        NSLog(@"%@: locale did changed", NSStringFromSelector(_cmd));
#endif
        [self reloadViewData];
    }
    else if ([aKeyPath isEqualToString:@"representedObject.date"])
    {
        NSCalendar *calendar = [self representedObject].calendar;
        NSDateComponents *oldDateComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                          fromDate:[aChange objectForKey:NSKeyValueChangeOldKey]];
        NSDateComponents *newDateComponents = [calendar components:NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
                                                          fromDate:[aChange objectForKey:NSKeyValueChangeNewKey]];
        if (![oldDateComponents isEqual:newDateComponents])
        {
#ifdef DEBUG
            NSLog(@"%@ date did changed to %@", NSStringFromSelector(_cmd), [aChange objectForKey:NSKeyValueChangeNewKey]);
#endif
            [self reloadViewData];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
