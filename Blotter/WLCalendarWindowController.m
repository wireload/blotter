//
//  WLCalendarWindowController.m
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarWindowController.h"
#import "WLCalendarRemindersViewController.h"
#import "WLCalendarDateViewController.h"
#import "WLCalendarBoxView.h"
#import "WLCalendarWindowBringToFrontAnimation.h"
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLCalendarRemindersController.h"
#import "WLCalendarEventsController.h"
#import "WLCalendarFloatingWeekEventsViewController.h"
#import "WLCalendarRightNowEventsViewController.h"


// Sizes are chosen so that when switching between these 2 modes only week view is disappeard. that is the date, todo and right now vies are visually unchanged.
const NSSize BLNarrowMinimumSize = {308, 718};

const NSSize BLNormalMinimumSize = {950, 718};

/**
    This is the overall smallest possible size for Blotter when using custom sizing.
*/
const NSSize BLMinimumSize = {280, 215};


static const CGFloat _WLFadeOutAlphaValue = 0.5;


@implementation WLCalendarWindowController
{
    id _calendarsObserver;
    WLCalendarRemindersController *_remindersController;
    WLCalendarEventsController *_eventsController;
    WLSmartClock *_smartClock;

    WLASLLog *_log;
}

- (id)init
{
    self = [self initWithWindow:[[[WLCalendarWindow alloc] init] autorelease]];
    if (self != nil)
    {
    }
    return self;
}

- (id)initWithWindow:(WLCalendarWindow *)aWindow
{
    NSParameterAssert([aWindow isKindOfClass:[WLCalendarWindow class]]);
    self = [super initWithWindow:aWindow];

    if (self != nil)
    {
        _log = [[WLASLLog alloc] initWithName:@"Calendar Window"];
        [aWindow setDelegate:self];

        windowState = WLFinderLevelState;

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

        // It's important to allocate "consumers" before calendars controller because they MUST exists at time
        // when WLCalCalendarsToDisplayDidChangeNotification is fired which can happen just after calendarsController is initialized.
        NSArray *calStores = @[[WLCalendarStore systemStore]]; // TODO: should be configurable
        _remindersController = [[WLCalendarRemindersController alloc] initWithCalStores:calStores];
        _eventsController = [[WLCalendarEventsController alloc] initWithCalStores:calStores];
        _calendarsController = [[WLCalendarsController alloc] initWithCalStores:calStores
                                                                autosaveKeyPath:@"Calendars"];

        void (^updateCalendars)(NSArray *aStores) = ^(NSArray *aStores)
        {
            for (NSObject<WLCalStore> *s in aStores)
            {
                NSArray *reminderCalendars = [[self.calendarsController calReminderCalendarsToDisplayForStore:s] valueForKey:@"calendarIdentifier"];
                [_log logDebugWithMessenger:^NSString *
                {
                    return [NSString stringWithFormat:@"Observed Reminder Calendars: %@", reminderCalendars];
                }];
                [_remindersController setObservedCalendarIdentifiers:reminderCalendars forStore:s];

                NSArray *eventCalendars = [[self.calendarsController calEventCalendarsToDisplayForStore:s] valueForKey:@"calendarIdentifier"];
                [_log logDebugWithMessenger:^NSString *
                {
                    return [NSString stringWithFormat:@"Observed Event Calendars: %@", eventCalendars];
                }];
                [_eventsController setObservedCalendarIdentifiers:eventCalendars forStore:s];
            }
        };

        _calendarsObserver = [defaultCenter addObserverForName:WLCalCalendarsToDisplayDidChangeNotification
                                                        object:_calendarsController
                                                         queue:nil
                                                    usingBlock:^(NSNotification *aNotification)
        {
            updateCalendars([[aNotification userInfo] objectForKey:WLChangedCalStoresKey]);
        }];

        updateCalendars([_calendarsController calStores]);

        _weekViewController = [[WLCalendarFloatingWeekEventsViewController alloc] initWithNibName:nil bundle:nil];
        _weekViewController.representedObject = _eventsController;
        [_weekViewController bind:@"titleFormat" toObject:defaults withKeyPath:WLTitleFormatKey options:nil];

        _rightNowViewController = [[WLCalendarRightNowEventsViewController alloc] init];
        [_rightNowViewController setAlignmentUnit:NSDayCalendarUnit number:1 animated:NO];
        _rightNowViewController.representedObject = _eventsController;

        _smartClock = [WLSmartClock defaultClock];
        [_smartClock addObserver:self forKeyPath:@"calendar" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
        [_smartClock addObserver:self forKeyPath:@"date" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];

        _remindersViewController = [[WLCalendarRemindersViewController alloc] initWithNibName:nil bundle:nil];
        _remindersViewController.representedObject = _remindersController;

        _dateViewController = [[WLCalendarDateViewController alloc] init];
        [_dateViewController setRepresentedObject:_smartClock];

        [defaults addObserver:self forKeyPath:@"CalendarSize" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"CalendarPosition" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:WLScreenIdentifierKey options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"CustomFrameFactors" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"InfoViewsWidth" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"DateViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:@"AllDayViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
        [defaults addObserver:self forKeyPath:WLShowsNext7DaysKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];

        [defaultCenter addObserver:self
                          selector:@selector(_updateFrame)
                              name:NSApplicationDidChangeScreenParametersNotification
                            object:NSApp];
    }

    return self;
}

- (void)dealloc
{
    [_weekViewController release];
    [_rightNowViewController release];
    [_remindersViewController release];
    [_dateViewController release];
    [_tasksViewBox release];
    [_rightNowViewBox release];

    [_fadeOutAnimation stopAnimation];
    [_fadeOutAnimation release];
    [_fadeInAnimation stopAnimation];
    [_fadeInAnimation release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"InfoViewsWidth"];
    [defaults removeObserver:self forKeyPath:@"DateViewHeight"];
    [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
    [defaults removeObserver:self forKeyPath:@"AllDayViewHeight"];
    [defaults removeObserver:self forKeyPath:@"CalendarSize"];
    [defaults removeObserver:self forKeyPath:@"CalendarPosition"];
    [defaults removeObserver:self forKeyPath:WLScreenIdentifierKey];
    [defaults removeObserver:self forKeyPath:@"CustomFrameFactors"];

    [_smartClock removeObserver:self forKeyPath:@"calendar"];
    [_smartClock removeObserver:self forKeyPath:@"date"];

    [_remindersController release];
    [_calendarsController release];
    [_log release];
    [super dealloc];
}


#pragma mark Properties
@synthesize windowState;
@synthesize isFadedOut;

- (void)setWindowState:(WLCalendarWindowState)newWindowState
{
    [self setWindowState:newWindowState animated:NO duration:0.0];
}

- (void)setIsFadedOut:(BOOL)newIsFadedOut
{
    if (newIsFadedOut != isFadedOut)
    {
        [self willChangeValueForKey:@"isFadedOut"];
        isFadedOut = newIsFadedOut;
        [NSAnimationContext beginGrouping];
        if ([[NSUserDefaults standardUserDefaults] WL_slowsAnimation])
            [[NSAnimationContext currentContext] setDuration:[[NSAnimationContext currentContext] duration] * 10];
        if (![self isAnimatingWindowState] && self.windowState == WLFinderLevelState)
        {
            if (isFadedOut)
                [[[self window] animator] setAlphaValue:_WLFadeOutAlphaValue];
            else
                [[self window] setAlphaValue:1.0];
        }
        else
        {
            // setWindowState animation will handle isFadedOut property automatically.
        }
        [NSAnimationContext endGrouping];
        [self didChangeValueForKey:@"isFadedOut"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfWindowState
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfIsFadedOut
{
    return NO;
}


#pragma mark Methods

- (IBAction)showNextWeek:(id)aSender
{
    if ([self canShowNextWeek])
        [_weekViewController showNextWeek:aSender animated:YES];
}

- (IBAction)showPreviousWeek:(id)aSender
{
    if ([self canShowPreviousWeek])
        [_weekViewController showPreviousWeek:aSender animated:YES];
}

- (IBAction)showCurrentWeek:(id)aSender
{
    if ([self canShowCurrentWeek])
        [_weekViewController showCurrentWeek:aSender animated:YES];
}

- (BOOL)canShowNextWeek
{
    return _isWindowShowed && ![[_weekViewController view] isHidden] && _weekViewController.canShowNextWeek;
}

- (BOOL)canShowCurrentWeek
{
    return _isWindowShowed && ![[_weekViewController view] isHidden] && _weekViewController.canShowCurrentWeek;
}

- (BOOL)canShowPreviousWeek
{
    return _isWindowShowed && ![[_weekViewController view] isHidden] && _weekViewController.canShowPreviousWeek;
}

- (BOOL)isCurrentWeekShowed
{
    NSParameterAssert(_isWindowShowed);

    return _weekViewController.weekOffset == 0;
}

- (void)setWindowState:(WLCalendarWindowState)newWindowState animated:(BOOL)isAnimated duration:(NSTimeInterval)aDuration;
{
    NSParameterAssert(_fadeOutAnimation == nil || _fadeInAnimation == nil);

    /*
     | = current position
                        set level
     1.0        0.5        0.0        0.5       1.0
     |--------------------------------------------> alpha value
     */
    if (isAnimated)
    {
        if (newWindowState == windowState)
            return;

        [self willChangeValueForKey:@"windowState"];
        windowState = newWindowState;
        [self didChangeValueForKey:@"windowState"];

        if (_fadeOutAnimation == nil && _fadeInAnimation == nil)
        {
            /*
             1.0                                        0.0
             |--------------------------------------------> alpha value

             No animation is running.
             */
            _fadeOutAnimation = [[WLCalendarWindowBringToFrontAnimation alloc] initWithWindow:[self window]];
            [_fadeOutAnimation setDelegate:self];
            [_fadeOutAnimation setAnimationBlockingMode:NSAnimationNonblocking];
            [_fadeOutAnimation setDuration:aDuration / 2.0];
            [_fadeOutAnimation setCurrentProgress:1.0 - [[self window] alphaValue]];
            [_fadeOutAnimation startAnimation];
        }
        else if (_fadeOutAnimation != nil)
        {
            /*
             1.0                                        0.0
             ------------------|--------------------------> alpha value
             <----progress---->

             Window is fading out, level is not changed yet.
             */
            [_fadeOutAnimation stopAnimation];
            NSTimeInterval duration = aDuration / 2.0;
            // Invert progress, because value will be inverted again in -animation:valueForProgress:
            NSAnimationProgress progress = 1.0 - [_fadeOutAnimation currentProgress];
            [_fadeOutAnimation release];
            _fadeOutAnimation = nil;

            _fadeInAnimation = [[WLCalendarWindowBringToFrontAnimation alloc] initWithWindow:[self window]];
            [_fadeInAnimation setDelegate:self];
            [_fadeInAnimation setAnimationBlockingMode:NSAnimationNonblocking];
            [_fadeInAnimation setDuration:duration];
            [_fadeInAnimation setCurrentProgress:progress];
            [_fadeInAnimation startAnimation];
        }
        else /* if (_fadeInAnimation != nil) */
        {
            /*
             1.0        0.5        0.0        0.5       1.0
             ------------------------------------------|--> alpha value
                                     <----progress---->

             Window is fading in, level is already changed.
             */
            [_fadeInAnimation stopAnimation];
            NSTimeInterval duration = aDuration / 2.0;
            // Invert progress, because value will be inverted again in -animation:valueForProgress:
            NSAnimationProgress progress = 1.0 - [_fadeInAnimation currentProgress];
            [_fadeInAnimation release];
            _fadeInAnimation = nil;

            _fadeOutAnimation = [[WLCalendarWindowBringToFrontAnimation alloc] initWithWindow:[self window]];
            [_fadeOutAnimation setDelegate:self];
            [_fadeOutAnimation setAnimationBlockingMode:NSAnimationNonblocking];
            [_fadeOutAnimation setDuration:duration];
            [_fadeOutAnimation setCurrentProgress:progress];
            [_fadeOutAnimation startAnimation];
        }
    }
    else
    {
        if (_fadeOutAnimation == nil && _fadeInAnimation == nil)
        {
            if (newWindowState == windowState)
                return;

            [self willChangeValueForKey:@"windowState"];
            windowState = newWindowState;

            switch (windowState)
            {
                case WLFinderLevelState:
                    self.window.isFloatingWindow = NO;
                    if (self.isFadedOut)
                        [[self window] setAlphaValue:_WLFadeOutAlphaValue];
                    else
                        [[self window] setAlphaValue:1.0];
                    break;
                case WLFloatingLevelState:
                    [[self window] setAlphaValue:1.0];
                    self.window.isFloatingWindow = YES;
                    break;
            }
            [self didChangeValueForKey:@"windowState"];
        }
        else if (_fadeOutAnimation != nil)
        {
            if (newWindowState == windowState)
            {
                [self flushWindowState];
            }
            else
            {
                [self willChangeValueForKey:@"windowState"];
                windowState = newWindowState;
                [_fadeOutAnimation stopAnimation];
                [_fadeOutAnimation setCurrentProgress:0.0];
                [_fadeOutAnimation release];
                _fadeOutAnimation = nil;
                [self didChangeValueForKey:@"windowState"];
            }
        }
        else /* if (_fadeInAnimation != nil) */
        {
            if (newWindowState == windowState)
                [self flushWindowState];
            else
            {
                [self willChangeValueForKey:@"windowState"];
                windowState = newWindowState;

                [_fadeInAnimation stopAnimation];
                [_fadeInAnimation setCurrentProgress:1.0];
                [_fadeInAnimation release];
                _fadeInAnimation = nil;

                switch (windowState)
                {
                    case WLFinderLevelState:
                        self.window.isFloatingWindow = NO;
                        if (self.isFadedOut)
                            [[self window] setAlphaValue:_WLFadeOutAlphaValue];
                        else
                            [[self window] setAlphaValue:1.0];
                        break;
                    case WLFloatingLevelState:
                        [[self window] setAlphaValue:1.0];
                        self.window.isFloatingWindow = YES;
                        break;
                }
                [self didChangeValueForKey:@"windowState"];
            }
        }
    }
}

- (void)flushWindowState
{
    NSParameterAssert(_fadeOutAnimation == nil || _fadeInAnimation == nil);

    if (_fadeOutAnimation != nil)
    {
        [_fadeOutAnimation stopAnimation];
        [_fadeOutAnimation release];
        _fadeOutAnimation = nil;

        switch (self.windowState)
        {
            case WLFinderLevelState:
                self.window.isFloatingWindow = NO;
                if (self.isFadedOut)
                    [[self window] setAlphaValue:_WLFadeOutAlphaValue];
                else
                    [[self window] setAlphaValue:1.0];
                break;
            case WLFloatingLevelState:
                [[self window] setAlphaValue:1.0];
                self.window.isFloatingWindow = YES;
                break;
        }
    }
    else if (_fadeInAnimation != nil)
    {
        [_fadeInAnimation stopAnimation];
        [_fadeInAnimation setCurrentProgress:1.0];
        [_fadeInAnimation release];
        _fadeInAnimation = nil;
    }
}

- (BOOL)isAnimatingWindowState
{
    return (_fadeOutAnimation != nil || _fadeInAnimation != nil);
}


#pragma mark NSAnimationDelegate

- (float)animation:(NSAnimation *)anAnimation valueForProgress:(NSAnimationProgress)aProgress
{
    NSParameterAssert(_fadeOutAnimation == nil || _fadeInAnimation == nil);

    if (anAnimation == _fadeOutAnimation)
    {
        switch (self.windowState)
        {
            case WLFinderLevelState:
            {
                // If the window is faded out, we have to restore to fade out value.
                if (self.isFadedOut)
                    return (1.0 - aProgress) * _WLFadeOutAlphaValue;
                else
                    return 1.0 - aProgress;
            }
            case WLFloatingLevelState:
                return 1.0 - aProgress;
        }
    }
    else
    {
        switch (self.windowState)
        {
            case WLFinderLevelState:
            {
                // If the window is faded out, we have to restore to fade out value.
                if (self.isFadedOut)
                    return aProgress * _WLFadeOutAlphaValue;
                else
                    return aProgress;
            }
            case WLFloatingLevelState:
                return aProgress;
        }
    }
}

- (void)animationDidEnd:(NSAnimation *)anAnimation
{
    NSParameterAssert(_fadeOutAnimation == nil || _fadeInAnimation == nil);

    if (anAnimation == _fadeOutAnimation)
    {
        switch (self.windowState)
        {
            case WLFinderLevelState:
                self.window.isFloatingWindow = NO;
                break;
            case WLFloatingLevelState:
                self.window.isFloatingWindow = YES;
                break;
        }

        _fadeInAnimation = [[WLCalendarWindowBringToFrontAnimation alloc] initWithWindow:[self window]];
        [_fadeInAnimation setDelegate:self];
        [_fadeInAnimation setDuration:[_fadeOutAnimation duration]];
        [_fadeInAnimation setAnimationBlockingMode:NSAnimationNonblocking];
        [_fadeInAnimation startAnimation];

        [_fadeOutAnimation release];
        _fadeOutAnimation = nil;
    }
    else if (anAnimation == _fadeInAnimation)
    {
        [_fadeInAnimation release];
        _fadeInAnimation = nil;
    }
}


#pragma mark NSWindowController

- (WLCalendarWindow *)window
{
    return (WLCalendarWindow *)[super window];
}

- (IBAction)showWindow:(id)aSender
{
    if (!_isWindowShowed)
    {
        [self _makeViews];
        [self _updateFrame];
        self.window.isFloatingWindow = (self.windowState == WLFloatingLevelState);
        _isWindowShowed = YES;
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"InfoViewsWidth"] ||
        [aKeyPath isEqualToString:@"DateViewHeight"] ||
        [aKeyPath isEqualToString:@"TasksViewHeight"] ||
        [aKeyPath isEqualToString:@"AllDayViewHeight"])
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateFrame) object:nil];
        [self performSelector:@selector(_updateFrame) withObject:nil afterDelay:0.0];
    }
    else if ([aKeyPath isEqualToString:@"CalendarSize"] ||
             [aKeyPath isEqualToString:@"CalendarPosition"] ||
             [aKeyPath isEqualToString:WLScreenIdentifierKey] ||
             [aKeyPath isEqualToString:@"CustomFrameFactors"])
    {
        BLSize calendarSize = (BLSize)[[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"];
        if (![aKeyPath isEqualToString:@"CustomFrameFactors"] ||
            ([aKeyPath isEqualToString:@"CustomFrameFactors"] && calendarSize == BLCustomSize))
        {
            if (_isWindowShowed)
                [self _updateFrame];
        }
    }
    else if ([aKeyPath isEqualToString:WLShowsNext7DaysKey])
    {
        if ([aChange[NSKeyValueChangeNewKey] boolValue])
            [_weekViewController setAlignmentUnit:NSDayCalendarUnit number:7 animated:YES];
        else
        {
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
                [_weekViewController setAlignmentUnit:NSWeekCalendarUnit number:1 animated:YES];
            else
                [_weekViewController setAlignmentUnit:NSWeekOfMonthCalendarUnit number:1 animated:YES];
        }
    }
    else if ([aKeyPath isEqualToString:@"calendar"])
    {
        [_weekViewController setCalendar:aChange[NSKeyValueChangeNewKey] animated:YES];
        [_rightNowViewController setCalendar:aChange[NSKeyValueChangeNewKey] animated:YES];
    }
    else if ([aKeyPath isEqualToString:@"date"])
    {
        [_weekViewController setDate:aChange[NSKeyValueChangeNewKey] animated:YES];
        [_rightNowViewController setDate:aChange[NSKeyValueChangeNewKey] animated:YES];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation WLCalendarWindowController (Frame)

- (NSRect)windowFrame
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [self windowFrameOnScreen:[self windowScreen]
                        withPosition:(BLPosition)[defaults integerForKey:@"CalendarPosition"]
                                size:(BLSize)[defaults integerForKey:@"CalendarSize"]];
}

- (NSRect)windowFrameOnScreen:(NSScreen *)aScreen withPosition:(BLPosition)aPosition size:(BLSize)aSize
{
    if (aScreen == nil)
        return NSZeroRect;

    NSRect screenFrame = [aScreen visibleFrame];
    NSRect windowFrame = NSZeroRect;
    if (aSize != BLCustomSize)
    {
        static const NSSize Margin = {.width = 14.0, .height = 14.0};
        screenFrame = NSInsetRect(screenFrame, Margin.width, Margin.height);
        switch (aSize) {
            case BLNarrowSize:
                windowFrame.size.width = BLNarrowMinimumSize.width;
                windowFrame.size.height = fmin(BLNarrowMinimumSize.height, NSHeight(screenFrame));
                break;
            case BLNormalSize:
                windowFrame.size.width = fmax(BLNormalMinimumSize.width, NSWidth(screenFrame) / 2);
                windowFrame.size.height = fmax(BLNormalMinimumSize.height, NSHeight(screenFrame) / 2);
                break;
            case BLFullSize:
                windowFrame.size = screenFrame.size;
                break;
            default:
                break;
        }

        CGFloat px = 0.0;
        CGFloat py = 0.0;

        if (aPosition == BLPositionTopCenter ||
            aPosition == BLPositionCenterCenter ||
            aPosition == BLPositionBottomCenter)
        {
            px = floor(NSWidth(screenFrame) / 2.0 - NSWidth(windowFrame) / 2.0);
        }
        else if (aPosition == BLPositionTopRight ||
            aPosition == BLPositionCenterRight ||
            aPosition == BLPositionBottomRight)
        {
            px = NSWidth(screenFrame) - NSWidth(windowFrame);
        }

        if (aPosition == BLPositionTopLeft ||
            aPosition == BLPositionTopCenter ||
            aPosition == BLPositionTopRight)
        {
            py = NSHeight(screenFrame) - NSHeight(windowFrame);
        }
        else if (aPosition == BLPositionCenterLeft ||
            aPosition == BLPositionCenterCenter ||
            aPosition == BLPositionCenterRight)
        {
            py = NSHeight(screenFrame) / 2.0 - NSHeight(windowFrame) / 2.0;
        }
        windowFrame.origin = NSMakePoint(screenFrame.origin.x + px, screenFrame.origin.y + py);
    }
    else
    {
        NSRect customFrameFactos = NSRectFromString([[NSUserDefaults standardUserDefaults] stringForKey:@"CustomFrameFactors"]);
        windowFrame = NSMakeRect(screenFrame.origin.x + customFrameFactos.origin.x * screenFrame.size.width,
                                 screenFrame.origin.y + customFrameFactos.origin.y * screenFrame.size.height,
                                 customFrameFactos.size.width * screenFrame.size.width,
                                 customFrameFactos.size.height * screenFrame.size.height);
    }

    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        return NSIntegralRect(windowFrame);
    else
        return [aScreen backingAlignedRect:windowFrame options:NSAlignAllEdgesInward];
}

- (NSScreen *)windowScreen
{
    NSArray *screens = [NSScreen screens];
    NSNumber *screenIdentifier = [[NSUserDefaults standardUserDefaults] WL_screenIdentifier];
    if ([screens count] > 0)
    {
        NSUInteger index = NSNotFound;
        if (screenIdentifier != nil)
        {
            index = [screens indexOfObjectPassingTest:^(NSScreen *screen, NSUInteger idx, BOOL *stop)
            {
                return [[screen valueForKeyPath:@"deviceDescription.NSScreenNumber"] isEqualToNumber:screenIdentifier];
            }];
        }
        if (index != NSNotFound)
            return [screens objectAtIndex:index];
        else
            return [screens objectAtIndex:0];
    }
    else
        return nil;
}

@end


@implementation  WLCalendarWindowController (Layout)

// Belongs to the right now view.
static const CGFloat _WLYMarginBetweenTasksAndRightNow = 10.0;

// Belongs to the calendar view.
static const CGFloat _WLXMarginBetweenInfoAndWeek = 17.0;

// Belongs to the date view.
static const CGFloat _WLYMarginBetweenBoundsAndDate = -40.0;

- (void)_applyWindowSizeToViews
{
    switch ((BLSize)[[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"])
    {
        case BLNarrowSize:
            [self _applyNarrowSizeToViews];
            break;
        case BLCustomSize:
            [self _applyCustomSizeToViews];
            break;
        case BLNormalSize:
            [self _applyNormalSizeToViews];
            break;
        case BLFullSize:
            [self _applyFullSizeToViews];
            break;
    }
}

- (void)_applyNarrowSizeToViews
{
    // Ignore width for info section, but don't overwrite it in user defaults.
    CGFloat width = [[self.window contentView] bounds].size.width;

    [self _applyCustomSizeToViews];

    NSRect r = [[_dateViewController view] frame];
    r.size.width = width;
    [[_dateViewController view] setFrame:r];
    [[_dateViewController view] setNeedsDisplay:YES];

    r = [_tasksViewBox frame];
    r.size.width = width;
    [_tasksViewBox setFrame:r];
    [_tasksViewBox setNeedsDisplay:YES];

    r = [_rightNowViewBox frame];
    r.size.width = width;
    [_rightNowViewBox setFrame:r];
    [_rightNowViewBox setNeedsDisplay:YES];

    [[_weekViewController view] setHidden:YES];
}

- (void)_applyCustomSizeToViews
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSRect dateViewFrame = [self dateViewFrame];
    NSSize minimumDateViewSize = NSMakeSize([defaults floatForKey:@"MinimumDateViewWidth"],
                                            [defaults floatForKey:@"MinimumDateViewHeight"]);
    BOOL showDateView = (dateViewFrame.size.width >= minimumDateViewSize.width &&
                         dateViewFrame.size.height >= minimumDateViewSize.height);
    [[_dateViewController view] setHidden:!showDateView];
    [[_dateViewController view] setFrame:dateViewFrame];
    [[_dateViewController view] setNeedsDisplay:YES];

    NSRect tasksViewFrame = [self tasksViewFrame];
    NSSize minimumTasksViewSize = NSMakeSize([defaults floatForKey:@"MinimumTasksViewWidth"],
                                             [defaults floatForKey:@"MinimumTasksViewHeight"]);
    BOOL showTasksView = (tasksViewFrame.size.width >= minimumTasksViewSize.width &&
                          tasksViewFrame.size.height >= minimumTasksViewSize.height);
    [_tasksViewBox setHidden:!showTasksView];
    [_tasksViewBox setFrame:tasksViewFrame];
    [_tasksViewBox setNeedsDisplay:YES];

    NSRect rightNowViewFrame = [self rightNowViewFrame];
    NSSize minimumRightNowViewSize = NSMakeSize([defaults floatForKey:@"MinimumRightNowViewWidth"],
                                                [defaults floatForKey:@"MinimumRightNowViewHeight"]);
    BOOL showRightNowView = (rightNowViewFrame.size.width >= minimumRightNowViewSize.width &&
                             rightNowViewFrame.size.height >= minimumRightNowViewSize.height);
    [_rightNowViewBox setHidden:!showRightNowView];
    [_rightNowViewBox setFrame:rightNowViewFrame];
    [_rightNowViewBox setNeedsDisplay:YES];

    NSRect weekViewFrame = [self weekViewFrame];
    [_weekViewController view].heightOfAllDayPartOfColumn = [defaults floatForKey:@"AllDayViewHeight"];
    [[_weekViewController view] setFrame:weekViewFrame];

    // Sizes in defaults know nothing about margins. Take care of them here.
    NSSize minimumWeekViewSize = NSMakeSize([defaults floatForKey:@"MinimumWeekViewWidth"] - _WLXMarginBetweenInfoAndWeek,
                                            [defaults floatForKey:@"MinimumWeekViewHeight"]);
    BOOL isTooSmall = (weekViewFrame.size.width < minimumWeekViewSize.width ||
                       weekViewFrame.size.height < minimumWeekViewSize.height);
    [[_weekViewController view] setHidden:isTooSmall];
    [[_weekViewController view] setNeedsDisplay:YES];
}

- (void)_applyNormalSizeToViews
{
    [self _applyCustomSizeToViews];
}

- (void)_applyFullSizeToViews
{
    [self _applyCustomSizeToViews];
}

- (void)_updateFrame
{
    NSRect windowFrame = [self windowFrame];
    BOOL shouldDisableUpdates = _isWindowShowed;
    if (shouldDisableUpdates)
        NSDisableScreenUpdates();
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction setCompletionBlock:^(void) {
        [self.window displayIfNeeded];
        if (shouldDisableUpdates)
            NSEnableScreenUpdates();
    }];
    [self flushWindowState];
    [self.window setFrame:windowFrame display:NO];
    [self _applyWindowSizeToViews];
    [CATransaction commit];
}

- (void)_makeViews
{
    NSParameterAssert(!_isWindowShowed);
    NSView *contentView = [self.window contentView];
    [contentView setWantsLayer:YES];
    [contentView setAutoresizesSubviews:NO];
    if ([[NSUserDefaults standardUserDefaults] WL_slowsAnimation])
        [contentView layer].speed = 0.1;

    NSView *dateView = [_dateViewController view];
    [dateView setWantsLayer:YES];
    [contentView addSubview:dateView];

    _tasksViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _tasksViewBox.title = NSLocalizedString(@"To Do", @"Header of To Do items list");
    _tasksViewBox.contentView = [_remindersViewController view];
    [_tasksViewBox setWantsLayer:YES];
    [contentView addSubview:_tasksViewBox];
    [_tasksViewBox release];

    _rightNowViewBox = [[WLCalendarBoxView alloc] initWithFrame:NSZeroRect];
    _rightNowViewBox.title = NSLocalizedString(@"Right Now", @"Header of Right Now items list");
    _rightNowViewBox.contentView = [_rightNowViewController view];
    _rightNowViewBox.softEdges = YES;
    [_rightNowViewBox setWantsLayer:YES];
    [contentView addSubview:_rightNowViewBox];
    [_rightNowViewBox release];

    [contentView addSubview:[_weekViewController view]];
}

- (CGFloat)fixedInfoViewsWidth
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat infoViewWidth = [defaults floatForKey:@"InfoViewsWidth"];
    CGFloat minWeekWidth = [defaults floatForKey:@"MinimumWeekViewWidth"];
    NSRect bounds = [[[self window] contentView] bounds];
    CGFloat weekWidth = NSWidth(bounds) - infoViewWidth;
    if (weekWidth > minWeekWidth)
        return infoViewWidth;
    else if (weekWidth < minWeekWidth / 2.0)
        return NSWidth(bounds);
    else
        return NSWidth(bounds) - minWeekWidth;
}

- (NSRect)dateViewFrame
{
    NSRect bounds = [[[self window] contentView] bounds];
    NSRect r = [[[self window] contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMinY(bounds) + _WLYMarginBetweenBoundsAndDate,
                                                               [self fixedInfoViewsWidth],
                                                               [[NSUserDefaults standardUserDefaults] floatForKey:@"DateViewHeight"] - _WLYMarginBetweenBoundsAndDate)];
    r.origin.x = fmax(NSMinX(bounds), fmin(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmax(NSMinY(bounds) + _WLYMarginBetweenBoundsAndDate, fmin(NSMaxY(bounds), r.origin.y));
    r.size.width = fmin(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fmin(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)tasksViewFrame
{
    NSRect bounds = [[[self window] contentView] bounds];
    // By default tasks and right now have the same height. Since window size is unknown until user start blotter
    // set the default value here.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"TasksViewHeight"] == nil || [defaults integerForKey:@"CalendarLayout"] == WLCalendarNormalLayout)
    {
        [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
        [defaults setFloat:[self defaultTasksViewHeight] forKey:@"TasksViewHeight"];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
    }
    else if ([defaults integerForKey:@"CalendarLayout"] == WLCalendarToDoLayout)
    {
        [defaults removeObserver:self forKeyPath:@"TasksViewHeight"];
        [defaults setFloat:[self fullTasksViewHeight] forKey:@"TasksViewHeight"];
        [defaults addObserver:self forKeyPath:@"TasksViewHeight" options:NSKeyValueObservingOptionNew context:NULL];
    }
    NSRect r = [[[self window] contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMaxY([self dateViewFrame]),
                                                               [self fixedInfoViewsWidth],
                                                               [defaults floatForKey:@"TasksViewHeight"])];
    r.origin.x = fmax(NSMinX(bounds), fmin(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmax(NSMinY(bounds), fmin(NSMaxY(bounds), r.origin.y));
    r.size.width = fmin(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fmin(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)rightNowViewFrame
{
    NSRect tasksViewFrame = [self tasksViewFrame];
    CGFloat margin = 0.0;
    if (fabs(tasksViewFrame.size.height - 0.0) > FLT_EPSILON)
        margin = _WLYMarginBetweenTasksAndRightNow;
    NSRect bounds = [[self.window contentView] bounds];
    NSRect r = [[[self window] contentView] centerScanRect:NSMakeRect(NSMinX(bounds),
                                                               NSMaxY(tasksViewFrame) + margin,
                                                               [self fixedInfoViewsWidth],
                                                               NSHeight(bounds) - NSMaxY([self tasksViewFrame]) - margin)];
    r.origin.x = fmax(NSMinX(bounds), fmin(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmax(NSMinY(bounds) + margin, fmin(NSMaxY(bounds), r.origin.y));
    r.size.width = fmin(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fmin(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (NSRect)weekViewFrame
{
    NSRect bounds = [[[self window] contentView] bounds];
    CGFloat infoViewWidth = [self fixedInfoViewsWidth];
    if (fabs(infoViewWidth - 0.0) > FLT_EPSILON)
        infoViewWidth += _WLXMarginBetweenInfoAndWeek;
    NSRect r = [[[self window] contentView] centerScanRect:NSMakeRect(NSMinX(bounds) + infoViewWidth,
                                                               NSMinY(bounds),
                                                               NSWidth(bounds) - infoViewWidth,
                                                               NSHeight(bounds))];
    r.origin.x = fmax(NSMinX(bounds), fmin(NSMaxX(bounds), r.origin.x));
    r.origin.y = fmax(NSMinY(bounds), fmin(NSMaxY(bounds), r.origin.y));
    r.size.width = fmin(NSMaxX(bounds) - r.origin.x, r.size.width);
    r.size.height = fmin(NSMaxY(bounds) - r.origin.y, r.size.height);
    return r;
}

- (CGFloat)defaultTasksViewHeight
{
    NSRect bounds = [[self.window contentView] bounds];
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    return round((NSHeight(bounds) - ([[defaults objectForKey:@"DateViewHeight"] floatValue]) - _WLYMarginBetweenTasksAndRightNow) / 2);
}

- (CGFloat)fullTasksViewHeight
{
    NSRect bounds = [[self.window contentView] bounds];
    NSURL *defaultsURL = [[NSBundle mainBundle] URLForResource:@"defaults" withExtension:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfURL:defaultsURL];
    return round(NSHeight(bounds) - ([[defaults objectForKey:@"DateViewHeight"] floatValue]));
}

- (NSSize)minimumSize
{
    return BLMinimumSize;
}

@end
