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


@implementation PositionPrefController

#pragma mark SS_PreferencePaneProtocol

- (WLPrefPaneView *)paneView
{
    if (_mainView == nil)
    {
        if ([NSBundle loadNibNamed:@"PositionPrefPaneView" owner:self])
        {
            _mainView.preferredFrameSize = [_mainView frame].size;
            [_positionView bind:NSValueBinding
                       toObject:[NSUserDefaults standardUserDefaults]
                    withKeyPath:@"CalendarPosition"
                        options:nil];
            WLCalendarSizeToPositionPrefPaneSizeTransformer *t = [[WLCalendarSizeToPositionPrefPaneSizeTransformer alloc] initWithDefaultSize:[_mainView frame].size];
            [_mainView bind:@"preferredFrameSize"
                   toObject:[NSUserDefaults standardUserDefaults]
                withKeyPath:@"CalendarSize"
                    options:[NSDictionary dictionaryWithObject:t forKey:NSValueTransformerBindingOption]];
            [t release];
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

@end
