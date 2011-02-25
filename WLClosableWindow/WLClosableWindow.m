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

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    NSUInteger flags = [theEvent modifierFlags];
    if (!(flags & NSControlKeyMask)
        && !(flags & NSAlternateKeyMask)
        && (flags & NSCommandKeyMask)
        && [theEvent keyCode] == kVK_ANSI_W)
    {
        [self performClose:theEvent];
        return YES;
    }
    return NO;
}

@end
