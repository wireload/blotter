//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"


@implementation PositionPrefController

- (NSArray *)calendarSizes
{
    return [NSArray arrayWithObjects:@"Narrow", @"Normal", @"Full", nil];
}

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
    return @"Positioning";
}

- (NSImage *)paneIcon
{
    return [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kToolbarDesktopFolderIcon)];

}

- (NSString *)paneToolTip
{
    return @"Position and Size Preferences";
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
