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

- (BOOL)beginRecording
{
    BOOL didBegin = [super beginRecording];

    if (didBegin)
        [[PTHotKeyCenter sharedCenter] pause];

    return didBegin;
}

- (void)endRecordingWithObjectValue:(NSDictionary *)anObjectValue
{
    [super endRecordingWithObjectValue:anObjectValue];
    [[PTHotKeyCenter sharedCenter] resume];
}

@end
