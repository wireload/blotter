//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"
#import "WLCalendarSizeToPositionPrefPaneSizeTransformer.h"
#import "WLPrefPaneView.h"
#import "DeskboardAppDelegate.h"


@implementation PositionPrefController

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"CalendarSize"];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"ScreenIdentifier"];
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

            _mainView.preferredFrameSize = [_mainView frame].size;
            [_mainView bind:@"preferredFrameSize"
                   toObject:[NSUserDefaults standardUserDefaults]
                withKeyPath:@"CalendarSize"
                    options:[NSDictionary dictionaryWithObject:[[[WLCalendarSizeToPositionPrefPaneSizeTransformer alloc] initWithDefaultSize:[_mainView frame].size] autorelease]
                                                        forKey:NSValueTransformerBindingOption]];

            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"CalendarSize"
                                                       options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior
                                                       context:NULL];
            [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"ScreenIdentifier" options:NSKeyValueObservingOptionNew context:NULL];
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
        [[_arrangement layer] setNeedsLayout];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end
