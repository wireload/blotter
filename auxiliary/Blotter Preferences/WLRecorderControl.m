//
//  WLRecorderControl.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 04.04.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLRecorderControl.h"
#import "PTHotKeyCenter.h"


@implementation WLRecorderControl

- (BOOL)becomeFirstResponder
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
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

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    BOOL result = [super performKeyEquivalent:anEvent];
    [self resignFirstResponder];
    return result;
}

@end
