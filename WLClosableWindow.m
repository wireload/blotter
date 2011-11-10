//
//  WLClosableWindow.m
//  Quiet
//
//  Created by Ilya Kulakov on 02.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "WLClosableWindow.h"


@implementation WLClosableWindow

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    NSUInteger flags = [anEvent modifierFlags];
    if ((!(flags & NSControlKeyMask) && !(flags & NSAlternateKeyMask) && (flags & NSCommandKeyMask) && [anEvent keyCode] == kVK_ANSI_W) ||
        [anEvent keyCode] == kVK_Escape)
    {
        [self makeFirstResponder:nil];
        [self performClose:anEvent];
        return YES;
    }
    else
        return [super performKeyEquivalent:anEvent];
}

- (void)close
{
    [self makeFirstResponder:nil];
    [super close];
}

@end
