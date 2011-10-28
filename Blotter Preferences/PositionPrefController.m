//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"
#import "WLPrefPaneView.h"
#import "DeskboardAppDelegate.h"


@implementation PositionPrefController

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"CalendarSize"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ScreenIdentifier"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"PositionPrefPaneView" owner:self])
        {
            [_arrangement createLayers];
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Recreated-Aqua" ofType:@"jpg"];
            NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfFile:path];
            _arrangement.backgroundImage = backgroundImage;
            [backgroundImage release];
            switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"]) {
                case BLCustomSize:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement | WLCalendarWindowResizingArrangement;
                    break;
                default:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement;
                    break;
            }

            defaultFrameSize = [_mainView frame].size;
            [self updatePreferredFrameSize];

            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CalendarSize"
                                                       options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
                                                       context:NULL];
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"ScreenIdentifier" options:NSKeyValueObservingOptionNew context:NULL];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updatePreferredFrameSize)
                                                         name:NSApplicationDidChangeScreenParametersNotification
                                                       object:NSApp];
        }
        else
            NSLog(@"Cannot load PositionPrefPaneView");
    }
    return _mainView;
}

- (NSString *)paneName
{
    return NSLocalizedStringFromTableInBundle(@"Positioning", nil, [NSBundle bundleForClass:[self class]], @"Positioing pref pane title");
}

- (NSImage *)paneIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kToolbarDesktopFolderIcon)];

}

- (NSString *)paneToolTip
{
    return NSLocalizedStringFromTableInBundle(@"Position and Size Preferences", nil, [NSBundle bundleForClass:[self class]], @"Positioning pref pane tooltip");
}

- (BOOL)allowsHorizontalResizing
{
    return NO;
}

- (BOOL)allowsVerticalResizing
{
    return NO;
}

#pragma mark ViewSize

/*
 Calculate how large this preferences pane should be given the current screen and calendar size settings. The aspect ratio of the screen, and whether we are using a Custom size or not decide how large the positioner control should be.
 
 Since default size may be different for different localizations, the default frame size must have been saved in `defaultFrameSize`. It is assumed the initial aspect ratio of the positioner is 16:10 + 1 px height (for the bottom shine line), and that the margins are 112, 20, 20, 20. This size is 440x383 in English for a 400x251 positioner control.
*/
- (NSSize)preferredFrameSize
{
    // XXX This has to be changed if more controls are added on the top of the position pref pane.
    static const NSSize PositionerMargins = {.width = 40.0, .height = 132.0};
    const NSSize DoubledPositionControlSize = {.width = 2 * (defaultFrameSize.width - PositionerMargins.width) + PositionerMargins.width, .height = 2 * (defaultFrameSize.height - PositionerMargins.height) + PositionerMargins.height };
    
    int calendarSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarSize"];
    NSSize r = calendarSize == BLCustomSize ? DoubledPositionControlSize : defaultFrameSize;
    
    // The new screen might have a different aspect ratio than the default 16:10.
    WLCalendarWindowController *w = [(DeskboardAppDelegate *)[NSApp delegate] calendarWindowController];
    NSScreen *windowScreen = [w windowScreen];
    
    NSRect screenFrame = [windowScreen frame];
    float aspectRatio = screenFrame.size.height ? screenFrame.size.width / screenFrame.size.height : 16.0 / 10.0;
    // NSLog(@"aspect ratio: %f", aspectRatio);
    // Remove the margins on the left and the right so we can calculate the desired height of the positioner alone.
    float desiredHeight = (r.width - PositionerMargins.width) / aspectRatio;
    // NSLog(@"desired height for a positioner control of %f px width: %f", (r.width - PositionerMargins.width), desiredHeight);
    // Round to nearest multiple of 10 so that we get whole grid squares. This will slightly distort the aspect
    // ratio but it's the lesser of two evils.
    float adjustedDesiredHeight = 10.0 * roundf(desiredHeight / 10.0);
    // NSLog(@"adjusted desired height: %f", adjustedDesiredHeight);
    
    r.height = adjustedDesiredHeight + PositionerMargins.height;
    return r;    
}

- (void)updatePreferredFrameSize
{
    _mainView.preferredFrameSize = [self preferredFrameSize];
}


#pragma mark WLCalendarWindowArrangementDelegate

- (NSRect)windowFrameOfCalendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement
{
    WLCalendarWindowController *w = [(DeskboardAppDelegate *)[NSApp delegate] calendarWindowController];
    NSRect windowFrame = [w windowFrame];
    NSRect screenFrame = [[w windowScreen] visibleFrame];
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

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setFrame:(NSRect)aFrame
{
    NSRect bounds = [anArrangement positionerBounds];

    if (NSMinX(aFrame) < NSMinX(bounds))
    {
        aFrame.size.width = fminf(NSWidth(aFrame), NSWidth(bounds));
        aFrame.origin.x = NSMinX(bounds);
    }
    if (NSMaxX(aFrame) > NSMaxX(bounds))
    {
        aFrame.size.width = fminf(NSWidth(aFrame), NSWidth(bounds));
        aFrame.origin.x = NSMaxX(bounds) - NSWidth(aFrame);
    }

    if (NSMinY(aFrame) < NSMinY(bounds))
    {
        aFrame.size.height = fminf(NSHeight(aFrame), NSHeight(bounds));
        aFrame.origin.y = NSMinY(bounds);
    }
    if (NSMaxY(aFrame) > NSMaxY(bounds))
    {
        aFrame.size.height = fminf(NSHeight(aFrame), NSHeight(bounds));
        aFrame.origin.y = NSMaxY(bounds) - NSHeight(aFrame);
    }

    NSRect customFrameFractos = NSMakeRect(aFrame.origin.x / bounds.size.width,
                                           aFrame.origin.y / bounds.size.height,
                                           aFrame.size.width / bounds.size.width,
                                           aFrame.size.height / bounds.size.height);
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(customFrameFractos) forKey:@"CustomFrameFactors"];
    return aFrame;
}

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setPosition:(BLPosition)aPosition
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:aPosition forKey:@"CalendarPosition"];
    WLCalendarWindowController *w = [(DeskboardAppDelegate *)[NSApp delegate] calendarWindowController];
    NSScreen *windowScreen = [w windowScreen];
    NSRect windowFrame = [w windowFrameOnScreen:windowScreen
                                   withPosition:aPosition
                                           size:[defaults integerForKey:@"CalendarSize"]];
    NSRect screenFrame = [windowScreen visibleFrame];
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


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"CalendarSize"])
    {
        [self updatePreferredFrameSize];
        BLSize oldSize = [[aChange objectForKey:NSKeyValueChangeOldKey] integerValue];
        BOOL isPrior = [[aChange objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
        if (isPrior && oldSize != BLCustomSize)
        {
            BLPosition position = [[NSUserDefaults standardUserDefaults] integerForKey:@"CalendarPosition"];
            DeskboardAppDelegate *appDelegate = [NSApp delegate];
            NSScreen *screen = [appDelegate.calendarWindowController windowScreen];
            NSRect windowFrame = [appDelegate.calendarWindowController windowFrameOnScreen:screen withPosition:position size:oldSize];
            NSRect screenFrame = [screen visibleFrame];
            NSRect customFrameFractos = NSMakeRect(windowFrame.origin.x / screenFrame.size.width,
                                                   windowFrame.origin.y / screenFrame.size.height,
                                                   windowFrame.size.width / screenFrame.size.width,
                                                   windowFrame.size.height / screenFrame.size.height);
            [[NSUserDefaults standardUserDefaults] setObject:NSStringFromRect(customFrameFractos) forKey:@"CustomFrameFactors"];
        }
        else if (!isPrior)
        {
            switch ([[aChange objectForKey:NSKeyValueChangeNewKey] integerValue]) {
                case BLCustomSize:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement | WLCalendarWindowResizingArrangement;
                    break;
                default:
                    _arrangement.arrangementMode = WLCalendarWindowPositioningArrangement;
                    break;
            }
            [[_arrangement layer] setNeedsLayout];
        }
    }
    else if ([aKeyPath isEqualToString:@"ScreenIdentifier"])
    {
        [self updatePreferredFrameSize];
        [[_arrangement layer] setNeedsLayout];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
