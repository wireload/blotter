//
//  WLClosableWindow.m
//  Quiet
//
//  Created by Ilya Kulakov on 02.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "WLClosableWindow.h"
#import "WLEvents.h"


@implementation WLClosableWindow

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    if (WLDoesEventContainShortcut(anEvent, NSCommandKeyMask, kVK_ANSI_W))
    {
        [self performClose:anEvent];
        return YES;
    }
    else
        return [super performKeyEquivalent:anEvent];
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
    return 0.20f;
}

- (void)close
{
    [self makeFirstResponder:nil];
    [super close];
}

@end
