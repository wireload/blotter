//
//  PositionPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 05/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "PositionPrefController.h"


@implementation PositionPrefController

- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!positionView)
        loaded = [NSBundle loadNibNamed:@"PositionPrefPaneView" owner:self];

    if (loaded)
        return positionView;

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
