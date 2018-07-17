//
//  WLPositioningPreferences.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "WLPositioningPreferences.h"
#import "DeskboardAppDelegate.h"
#import "NSUserDefaults+WLApplicationDefaults.h"
#import "IKApplicationPreferences.h"


@implementation WLPositioningPreferences

- (void)dealloc
{
    if (self.isViewLoaded)
    {
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"CalendarSize"];
        [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLScreenIdentifierKey];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark Methods

- (void)updatePreferredFrameSizeOfPaneView
{
    /*
     Calculate how large this preferences pane should be given the current screen and calendar size settings. The aspect ratio of the screen, and whether we are using a Custom size or not decide how large the positioner control should be.

     Since default size may be different for different localizations, the default frame size must have been saved in `defaultFrameSize`. It is assumed the initial aspect ratio of the positioner is 16:10 + 1 px height (for the bottom shine line), and that the margins are minX=20, minY=20, maxX=20, maxY=91. This size is 440x383 in English for a 400x251 positioner control.
     */
    // XXX This has to be changed if more controls are added on the top of the position pref pane.
    static const NSSize PositionerMargins = {.width = 40.0, .height = 111.0};
    static const NSSize DoubledPositionControlSize = {.width = 840.0, .height = 611.0};
    NSInteger calendarSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"];
    NSSize preferredSize = calendarSize == BLCustomSize ? DoubledPositionControlSize : _defaultFrameSize;

    // The new screen might have a different aspect ratio than the default 16:10.
    WLCalendarWindowController *w = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSScreen *windowScreen = [w windowScreen];

    NSRect screenFrame = windowScreen.visibleFrame;
    CGFloat aspectRatio = screenFrame.size.height >= 0.0 ? screenFrame.size.width / screenFrame.size.height : 16.0 / 10.0;

    // Remove the margins on the left and the right so we can calculate the desired height of the positioner alone.
    CGFloat desiredHeight = (preferredSize.width - PositionerMargins.width) / aspectRatio;

    // Round to nearest multiple of 20 so that we get whole grid squares. This will slightly distort the aspect
    // ratio but it's the lesser of two evils.
    CGFloat adjustedDesiredHeight = 20.0 * round(desiredHeight / 20.0);

    preferredSize.height = adjustedDesiredHeight + PositionerMargins.height;

    IKApplicationPreferences *windowController = self.view.window.windowController;

    if (windowController != nil)
        [windowController setSelectedRepresentationViewSize:preferredSize animated:YES];
    else
        [self.view setFrameSize:preferredSize];
}


#pragma mark IKPreferencesRepresentation

- (void)configureToolbarItem:(NSToolbarItem *)anItem
{
    anItem.image = [NSImage imageNamed:@"preferences-positioning-icon"];
    anItem.label = NSLocalizedString(@"Positioning", @"Positioing pref pane title");
    anItem.toolTip = NSLocalizedString(@"Position and Size Preferences", @"Positioning pref pane tooltip");
}


#pragma mark WLCalendarWindowArrangementDelegate

- (NSRect)calendarWindowViewFrameOfCalendarWindowArrangement:(WLCalendarWindowArrangementView *)anArrangement
{
    WLCalendarWindowController *w = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSRect windowFrame = [w windowFrame];
    NSRect screenFrame = [w windowScreen].visibleFrame;
    if (!NSEqualRects(windowFrame, NSZeroRect) && !NSEqualRects(screenFrame, NSZeroRect))
    {
        // We have to map global screen coordinates to a local one.
        NSRect bounds = [anArrangement positionerBounds];
        windowFrame = NSOffsetRect(windowFrame, -screenFrame.origin.x, -screenFrame.origin.y);
        NSRect scaledWindowFrame = NSMakeRect(bounds.origin.x + bounds.size.width * windowFrame.origin.x / screenFrame.size.width,
                                              bounds.origin.y + bounds.size.height * windowFrame.origin.y / screenFrame.size.height,
                                              bounds.size.width * windowFrame.size.width / screenFrame.size.width,
                                              bounds.size.height * windowFrame.size.height / screenFrame.size.height);
        return [anArrangement centerScanRect:scaledWindowFrame];
    }
    else
        return NSZeroRect;
}

- (NSSize)minimumSizeForCalendarWindowArrangement:(WLCalendarWindowArrangementView *)anArrangement
{
    WLCalendarWindowController *w = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSRect screenFrame = [w windowScreen].visibleFrame;
    if (!NSEqualRects(screenFrame, NSZeroRect))
    {
        NSRect bounds = [anArrangement positionerBounds];
        return NSMakeSize(ceil([w minimumSize].width * bounds.size.width / screenFrame.size.width),
                          ceil([w minimumSize].height * bounds.size.height / screenFrame.size.height));
    }
    else
        return NSMakeSize(90, 70);

}

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangementView *)anArrangement setFrame:(NSRect)aFrame
{
    NSRect bounds = [anArrangement positionerBounds];

    if (NSMinX(aFrame) < NSMinX(bounds))
    {
        aFrame.size.width = fmin(NSWidth(aFrame), NSWidth(bounds));
        aFrame.origin.x = NSMinX(bounds);
    }
    if (NSMaxX(aFrame) > NSMaxX(bounds))
    {
        aFrame.size.width = fmin(NSWidth(aFrame), NSWidth(bounds));
        aFrame.origin.x = NSMaxX(bounds) - NSWidth(aFrame);
    }

    if (NSMinY(aFrame) < NSMinY(bounds))
    {
        aFrame.size.height = fmin(NSHeight(aFrame), NSHeight(bounds));
        aFrame.origin.y = NSMinY(bounds);
    }
    if (NSMaxY(aFrame) > NSMaxY(bounds))
    {
        aFrame.size.height = fmin(NSHeight(aFrame), NSHeight(bounds));
        aFrame.origin.y = NSMaxY(bounds) - NSHeight(aFrame);
    }

    NSRect customFrameFractos = NSMakeRect(aFrame.origin.x / bounds.size.width,
                                           aFrame.origin.y / bounds.size.height,
                                           aFrame.size.width / bounds.size.width,
                                           aFrame.size.height / bounds.size.height);
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(customFrameFractos) forKey:@"CustomFrameFactors"];
    return aFrame;
}

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangementView *)anArrangement setPosition:(BLPosition)aPosition
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:aPosition forKey:@"CalendarPosition"];
    WLCalendarWindowController *w = ((DeskboardAppDelegate *)NSApp.delegate).calendarWindowController;
    NSScreen *windowScreen = [w windowScreen];
    NSRect windowFrame = [w windowFrameOnScreen:windowScreen
                                   withPosition:aPosition
                                           size:[defaults integerForKey:@"CalendarSize"]];
    NSRect screenFrame = windowScreen.visibleFrame;
    if (!NSEqualRects(windowFrame, NSZeroRect) && !NSEqualRects(screenFrame, NSZeroRect))
    {
        // We have to map global screen coordinates to a local one.
        NSRect bounds = [anArrangement positionerBounds];
        windowFrame = NSOffsetRect(windowFrame, -screenFrame.origin.x, -screenFrame.origin.y);
        NSRect scaledWindowFrame = NSMakeRect((bounds.origin.x + bounds.size.width) * windowFrame.origin.x / screenFrame.size.width,
                                              (bounds.origin.y + bounds.size.height) * windowFrame.origin.y / screenFrame.size.height,
                                              bounds.size.width * windowFrame.size.width / screenFrame.size.width,
                                              bounds.size.height * windowFrame.size.height / screenFrame.size.height);
        return NSIntegralRect(scaledWindowFrame);
    }
    else
        return NSZeroRect;
}


#pragma marn NSViewController

- (void)loadView
{
    [super loadView];

    [_arrangement createLayers];
    NSImage *backgroundImage = [NSImage imageNamed:@"preferences-recreated-aqua"];
    _arrangement.backgroundImage = backgroundImage;

    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"]) {
        case BLCustomSize:
            _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement | WLCalendarWindowResizingArrangement;
            break;
        default:
            _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement;
            break;
    }

    _defaultFrameSize = self.view.frame.size;
    [self updatePreferredFrameSizeOfPaneView];

    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CalendarSize"
                                               options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:WLScreenIdentifierKey options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePreferredFrameSizeOfPaneView)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:NSApp];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"CalendarSize"])
    {
        BLSize oldSize = [aChange[NSKeyValueChangeOldKey] integerValue];
        BOOL isPrior = [aChange[NSKeyValueChangeNotificationIsPriorKey] boolValue];
        if (isPrior && oldSize != BLCustomSize)
        {
            BLPosition position = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarPosition"];
            DeskboardAppDelegate *appDelegate = NSApp.delegate;
            NSScreen *screen = [appDelegate.calendarWindowController windowScreen];
            NSRect windowFrame = [appDelegate.calendarWindowController windowFrameOnScreen:screen withPosition:position size:oldSize];
            NSRect screenFrame = screen.visibleFrame;
            NSRect customFrameFractos = NSMakeRect(fabs(windowFrame.origin.x - screenFrame.origin.x) / screenFrame.size.width,
                                                   fabs(windowFrame.origin.y - screenFrame.origin.y) / screenFrame.size.height,
                                                   windowFrame.size.width / screenFrame.size.width,
                                                   windowFrame.size.height / screenFrame.size.height);
            [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(customFrameFractos) forKey:@"CustomFrameFactors"];
        }
        else if (!isPrior)
        {
            switch ([aChange[NSKeyValueChangeNewKey] integerValue]) {
                case BLCustomSize:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement | WLCalendarWindowResizingArrangement;
                    break;
                default:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement;
                    break;
            }
            [_arrangement.layer setNeedsLayout];
            [self updatePreferredFrameSizeOfPaneView];
        }
    }
    else if ([aKeyPath isEqualToString:WLScreenIdentifierKey])
    {
        [self updatePreferredFrameSizeOfPaneView];
        [_arrangement.layer setNeedsLayout];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
