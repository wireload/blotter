//
//  WLCalendarRemindersView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarRemindersView.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


static NSString* const _WLRootLayerName = @"WLCalendarRemindersViewLayer";


@implementation WLCalendarRemindersView
{
    NSMutableArray *_orderedReminderLayers;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];

    if (self)
    {
        _orderedReminderLayers = [NSMutableArray array];
    }

    return self;
}


#pragma mark Methods

- (void)reloadData
{
    NSAssert(self.dataSource != nil, @"You MUST set dataSource");
    NSParameterAssert(self.layer != nil);

    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [_orderedReminderLayers removeAllObjects];
    for (NSUInteger i = 0, size = [self.dataSource numberOfRemindersInRemindersView:self]; i < size; ++i)
        [self insertReminderAtIndex:i];
}

- (void)insertReminderAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(self.layer != nil);
    NSAssert(anIndex <= [self numberOfReminders],
             @"anIndex (%ld) MUST be less or equal than number of tasks (%ld).", anIndex, [self numberOfReminders]);

    WLCalendarReminderLayer *l = [self makeReminderLayer];
    [self.layer addSublayer:l];
    [_orderedReminderLayers insertObject:l atIndex:anIndex];
    [self updateReminderAtIndex:anIndex];
    [self.layer setNeedsLayout];
}

- (void)removeReminderAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(self.layer != nil);
    NSAssert(anIndex < [self numberOfReminders],
    @"anIndex (%ld) MUST point to a valid task (%ld tasks).", anIndex, [self numberOfReminders]);

    WLCalendarReminderLayer *l = _orderedReminderLayers[anIndex];
    [_orderedReminderLayers removeObjectAtIndex:anIndex];
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [l removeFromSuperlayer];
    }];
    l.opacity = 0.0;
    [CATransaction commit];
    [self.layer setNeedsLayout];
}

- (void)updateReminderAtIndex:(NSUInteger)anIndex
{
    NSParameterAssert(self.layer != nil);
    NSAssert(anIndex < [self numberOfReminders],
             @"anIndex (%ld) MUST point to a valid reminder (%ld tasks).", anIndex, [self numberOfReminders]);

    NSObject<WLCalReminder> *reminder = [self.dataSource remindersView:self reminderAtIndex:anIndex];
    WLCalendarReminderLayer *l = _orderedReminderLayers[anIndex];
    l.name = reminder.itemIdentifier;
    l.title = [NSAttributedString WL_reminderTitleWithString:reminder.title];
    NSColor *calendarColor = reminder.calendar.color;

    l.mark = [NSAttributedString WL_reminderMarkWithColor:calendarColor.CGColor];
    [self.layer setNeedsLayout];
}

- (void)moveReminderAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    if (oldIndex == newIndex)
        return;

    NSParameterAssert(self.layer != nil);
    NSAssert(oldIndex < [self numberOfReminders],
             @"oldIndex (%ld) MUST point to a valid task (%ld tasks).", oldIndex, [self numberOfReminders]);
    NSAssert(newIndex < [self numberOfReminders],
             @"newIndex (%ld) MUST be less than number of tasks (%ld tasks).", newIndex, [self numberOfReminders]);

    NSObject<WLCalReminder> *l = _orderedReminderLayers[oldIndex];
    [_orderedReminderLayers removeObjectAtIndex:oldIndex];
    [_orderedReminderLayers insertObject:l atIndex:newIndex];
    [self.layer setNeedsLayout];
}

- (NSUInteger)numberOfReminders
{
    return _orderedReminderLayers.count;
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    if (aLayer != self.layer)
        return;

    // Origin is top left.
    CGFloat yOffsetFromTop = 0.0;
    static const CGFloat TopMargin = 9.0;

    for (WLCalendarReminderLayer *l in _orderedReminderLayers)
    {
        CGFloat preferredHeight = [l preferredHeightWithWidth:CGRectGetWidth(aLayer.bounds)];

        if (yOffsetFromTop < CGRectGetMaxY(aLayer.bounds))
        {
            if (yOffsetFromTop + preferredHeight <= CGRectGetMaxY(aLayer.bounds))
            {
                l.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                    yOffsetFromTop,
                                                    CGRectGetWidth(aLayer.bounds),
                                                    preferredHeight));
            }
            else
            {
                CGFloat minimumHeight = [l minimumHumanVisibleHeight];

                if (yOffsetFromTop + minimumHeight <= CGRectGetMaxY(aLayer.bounds))
                {
                    l.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                        yOffsetFromTop,
                                                        CGRectGetWidth(aLayer.bounds),
                                                        fdim(CGRectGetMaxY(aLayer.bounds), yOffsetFromTop)));
                }
                else
                {
                    l.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                        CGRectGetMaxY(aLayer.bounds),
                                                        CGRectGetWidth(aLayer.bounds),
                                                        preferredHeight));
                }
            }
        }
        else
        {
            l.frame = CGRectIntegral(CGRectMake(CGRectGetMinX(aLayer.bounds),
                                                yOffsetFromTop,
                                                CGRectGetWidth(aLayer.bounds),
                                                preferredHeight));
        }

        yOffsetFromTop = CGRectGetMaxY(l.frame) + TopMargin;
    }
}


#pragma mark CALayerDelegate

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return nil;
}


#pragma mark WLLayerBackedView

- (CALayer *)makeHostedLayer
{
    CALayer *l = [super makeHostedLayer];

    l.layoutManager = self;
    l.masksToBounds = YES;
    l.name = _WLRootLayerName;
    NSDictionary *actions = @{kCAOnOrderIn: [NSNull null],
                             kCAOnOrderOut: [NSNull null],
                             kCATransition: [NSNull null],
                             @"contents": [NSNull null],
                             @"frame": [NSNull null],
                             @"bounds": [NSNull null],
                             @"position": [NSNull null]};
    l.actions = actions;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor blackColor] CGColor];
#endif

    return l;
}


#pragma mark NSView

- (BOOL)isFlipped
{
    return YES;
}

@end


@implementation WLCalendarRemindersView (Layers)

- (WLCalendarReminderLayer *)makeReminderLayer
{
    WLCalendarReminderLayer *l = [WLCalendarReminderLayer layer];

    NSWindow *window = self.window;

    if (window)
        l.contentsScale = window.backingScaleFactor;

    l.needsDisplayOnBoundsChange = YES;
    l.delegate = self;

#ifdef DEBUG_LAYERS
    l.backgroundColor = [[NSColor orangeColor] CGColor];
#endif

    return l;
}

@end
