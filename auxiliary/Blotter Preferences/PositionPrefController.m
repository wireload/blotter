//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"


@implementation PositionPrefController

- (id)init {
    if (self = [super init]) {
        screensObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationDidChangeScreenParametersNotification
                                                                            object:nil
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *arg1) {
                                                                            // We need to emulate "changing" of screens property to make array controller reload its content.
                                                                            [self willChangeValueForKey:@"screens"];
                                                                            [self didChangeValueForKey:@"screens"];
                                                                        }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:screensObserver];
    [super dealloc];
}

- (NSArray *)screens {
    return [NSScreen screens];
}


#pragma mark SS_PreferencePaneProtocol

- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!mainView)
    {
        loaded = [NSBundle loadNibNamed:@"PositionPrefPaneView" owner:self];

        if (loaded)
        {
            [positionView bind:NSValueBinding
                      toObject:[NSUserDefaultsController sharedUserDefaultsController]
                   withKeyPath:@"values.CalendarPosition"
                       options:0];
        }
    }

    if (loaded)
        return mainView;

    return nil;
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

@end
