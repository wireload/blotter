//
//  WLCalendarDateViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/17/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>

#import "WLCalendarDateViewController.h"


void *_WLSmartClockObserverContext = &_WLSmartClockObserverContext;


@implementation WLCalendarDateViewController
{
    NSTextField *_monthDayField;
    NSTextField *_monthAndYearField;
    NSTextField *_weekdayField;

    NSDateFormatter *_monthAndYearFormatter;
    NSDateFormatter *_weekdayFormatter;

    WLSmartClock *_clock;
}

#pragma mark Properties

- (WLSmartClock *)clock
{
    if (_clock == nil)
        _clock = WLSmartClock.defaultClock;

    return _clock;
}

#pragma mark NSView

- (void)updateViewContents
{
    static NSDictionary *MonthDayAttributes = nil;
    static NSDictionary *MonthAndYearAttributes = nil;
    static NSDictionary *WeekdayAttributes = nil;
    static dispatch_once_t OnceToken;
    dispatch_once(&OnceToken, ^{
        __auto_type shadow = [NSShadow new];
        shadow.shadowColor = [NSColor colorWithCalibratedRed:47.0 / 255.0
                                                       green:47.0 / 255.0
                                                        blue:47.0 / 255.0
                                                       alpha:0.25];
        shadow.shadowBlurRadius = 0.0;
        // Shadow direction is /not/ flipped.
        shadow.shadowOffset = NSMakeSize(0.0, -1.0);

        __auto_type paragraph = [NSMutableParagraphStyle new];
        paragraph.alignment = NSCenterTextAlignment;
        paragraph.lineBreakMode = NSLineBreakByClipping;

        __auto_type attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  NSColor.whiteColor, NSForegroundColorAttributeName,
                                  shadow, NSShadowAttributeName,
                                  paragraph, NSParagraphStyleAttributeName, nil];

        attributes[NSFontAttributeName] = [NSFont fontWithName:@"Helvetica Neue" size:200];
        MonthDayAttributes = [attributes copy];

        attributes[NSFontAttributeName] = [NSFont fontWithName:@"Helvetica Neue Light" size:26.0];
        MonthAndYearAttributes = [attributes copy];

        attributes[NSFontAttributeName] = [NSFont fontWithName:@"Helvetica Neue Light" size:26.0];
        WeekdayAttributes = [attributes copy];
    });

    NSDate *date = self.clock.date;

    NSInteger day = [self.clock.calendar components:NSCalendarUnitDay fromDate:date].day;
    NSString *value = [NSString stringWithFormat:@"%ld", day];
    _monthDayField.attributedStringValue = [[NSAttributedString alloc] initWithString:value attributes:MonthDayAttributes];

    value = [_monthAndYearFormatter stringFromDate:date];
    _monthAndYearField.attributedStringValue = [[NSAttributedString alloc] initWithString:value attributes:MonthAndYearAttributes];

    value = [_weekdayFormatter stringFromDate:date];
    _weekdayField.attributedStringValue = [[NSAttributedString alloc] initWithString:value attributes:WeekdayAttributes];
}

- (void)calendarDidChange
{
    NSCalendar *calendar = self.clock.calendar;
    _monthAndYearFormatter = [NSDateFormatter new];
    _monthAndYearFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMy"
                                                                        options:0
                                                                         locale:calendar.locale];
    _weekdayFormatter = [NSDateFormatter new];
    _weekdayFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"cccc"
                                                                   options:0
                                                                    locale:calendar.locale];
    [self updateViewContents];
}

- (void)dateDidChange
{
    [self updateViewContents];
}

#pragma mark NSViewController

- (void)loadView
{
    __auto_type MakeTextField = ^{
        NSTextField *f = [NSTextField new];
        f.editable = NO;
        f.alignment = NSTextAlignmentCenter;
        f.bezeled = NO;
        f.bordered = NO;
        f.drawsBackground = NO;
        f.lineBreakMode = NSLineBreakByTruncatingTail;
        f.selectable = NO;
        f.refusesFirstResponder = NO;
        [f setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
        [f setContentCompressionResistancePriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationVertical];
        return f;
    };

    _monthDayField = MakeTextField();
    _monthAndYearField = MakeTextField();
    _weekdayField = MakeTextField();

    [_monthDayField.heightAnchor constraintEqualToConstant:200.0].active = YES;

    __auto_type stackView = [NSStackView new];
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.alignment = NSLayoutAttributeCenterX;
    stackView.distribution = NSStackViewDistributionGravityAreas;
    stackView.detachesHiddenViews = YES;
    [stackView setViews:@[_monthDayField, _monthAndYearField, _weekdayField] inGravity:NSStackViewGravityTop];
    self.view = stackView;
}

- (void)viewWillAppear
{
    [super viewWillAppear];

    [self addObserver:self
           forKeyPath:@"clock.calendar"
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:_WLSmartClockObserverContext];
    [self addObserver:self
           forKeyPath:@"clock.date"
              options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
              context:_WLSmartClockObserverContext];
}

- (void)viewDidDisappear
{
    [self removeObserver:self
              forKeyPath:@"clock.calendar"
                 context:_WLSmartClockObserverContext];
    [self removeObserver:self
              forKeyPath:@"clock.date"
                 context:_WLSmartClockObserverContext];

    [super viewDidDisappear];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)aChange
                       context:(void *)aContext
{
    if (aContext == _WLSmartClockObserverContext)
    {
        if ([aKeyPath isEqualToString:@"clock.calendar"])
            [self calendarDidChange];
        else // @"date"
        {
            NSDate *oldDate = aChange[NSKeyValueChangeOldKey];

            if (!oldDate)
            {
                [self dateDidChange];
                return;
            }

            NSCalendar *calendar = self.clock.calendar;
            __auto_type components = NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
            __auto_type oldDateComponents = [calendar components:components fromDate:oldDate];
            __auto_type newDateComponents = [calendar components:components fromDate:aChange[NSKeyValueChangeNewKey]];

            if (![oldDateComponents isEqual:newDateComponents])
                [self dateDidChange];
        }
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
