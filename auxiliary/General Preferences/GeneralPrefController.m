//
//  GeneralPrefController.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "GeneralPrefController.h"
#import "PositionPrefController.h"

@implementation GeneralPrefController

+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPrefController alloc] init] autorelease], [[[PositionPrefController alloc] init] autorelease], nil];
}

- (NSView *)paneView
{
    BOOL loaded = YES;

    if (!prefsView)
        loaded = [NSBundle loadNibNamed:@"GeneralPrefPaneView" owner:self];

    if (loaded)
        return prefsView;

    return nil;
}

- (NSString *)paneName
{
    return @"General";
}

- (NSImage *)paneIcon
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}


- (NSString *)paneToolTip
{
    return @"General Preferences";
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
