//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"
#import "WLCalendarSizeToPositionPrefPaneSizeTransformer.h"
#import "WLCalendarSizeToArrangementModeTransformer.h"
#import "WLPrefPaneView.h"
#import "DeskboardAppDelegate.h"


@implementation PositionPrefController

#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"PositionPrefPaneView" owner:self])
        {
            [_positionView createLayers];
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Recreated-Aqua" ofType:@"jpg"];
            NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfFile:path];
            _positionView.backgroundImage = backgroundImage;
            [_positionView bind:@"arrangementMode"
                       toObject:[NSUserDefaults standardUserDefaults]
                    withKeyPath:@"CalendarSize"
                        options:[NSDictionary dictionaryWithObject:[[[WLCalendarSizeToArrangementModeTransformer alloc] init] autorelease]
                                                            forKey:NSValueTransformerBindingOption]];
            [backgroundImage release];
            _mainView.preferredFrameSize = [_mainView frame].size;
            [_mainView bind:@"preferredFrameSize"
                   toObject:[NSUserDefaults standardUserDefaults]
                withKeyPath:@"CalendarSize"
                    options:[NSDictionary dictionaryWithObject:[[[WLCalendarSizeToPositionPrefPaneSizeTransformer alloc] initWithDefaultSize:[_mainView frame].size] autorelease]
                                                        forKey:NSValueTransformerBindingOption]];
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
        NSRect bounds = [anArrangement bounds];
        windowFrame = NSOffsetRect(windowFrame, -screenFrame.origin.x, -screenFrame.origin.y);
        NSRect scaledWindowFrame = NSMakeRect(bounds.origin.x + bounds.size.width * windowFrame.origin.x / screenFrame.size.width,
                                              bounds.origin.y + bounds.size.height * windowFrame.origin.y / screenFrame.size.height,
                                              bounds.size.width * windowFrame.size.width / screenFrame.size.width,
                                              bounds.size.height * windowFrame.size.height / screenFrame.size.height);
        return NSIntegralRect(scaledWindowFrame);
    }
    else
        return NSZeroRect;
}

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setFrame:(NSRect)aFrame
{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSRect bounds = [anArrangement bounds];
//    [defaults setObject:[NSValue valueWithRect:NSMakeRect(aFrame.origin.x / bounds.size.width,
//                                                          aFrame.origin.y / bounds.size.height,
//                                                          aFrame.size.width / bounds.size.width,
//                                                          aFrame.size.height / bounds.size.height)]
//                 forKey:@"CalendarCustomFrame"];
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
        NSRect bounds = [anArrangement bounds];
        windowFrame = NSOffsetRect(windowFrame, -screenFrame.origin.x, -screenFrame.origin.y);
        NSRect scaledWindowFrame = NSMakeRect(bounds.origin.x + bounds.size.width * windowFrame.origin.x / screenFrame.size.width,
                                              bounds.origin.y + bounds.size.height * windowFrame.origin.y / screenFrame.size.height,
                                              bounds.size.width * windowFrame.size.width / screenFrame.size.width,
                                              bounds.size.height * windowFrame.size.height / screenFrame.size.height);
        return NSIntegralRect(scaledWindowFrame);
    }
    else
        return NSZeroRect;
}

@end
