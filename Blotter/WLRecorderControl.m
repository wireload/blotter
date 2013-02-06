//
//  WLRecorderControl.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <PTHotKey/PTHotKeyCenter.h>
#import "WLRecorderControl.h"


@implementation WLRecorderControl

- (BOOL)becomeFirstResponder
{
    BOOL isBecome = [super becomeFirstResponder];
    if (isBecome)
        [[PTHotKeyCenter sharedCenter] pause];
    return isBecome;
}

- (BOOL)resignFirstResponder
{
    BOOL isResigned = [super resignFirstResponder];
    if (isResigned)
        [[PTHotKeyCenter sharedCenter] resume];
    return isResigned;
}

@end
