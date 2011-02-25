//
//  WLClosablePanel.m
//  Blotter
//
//  Created by Ilya Kulakov on 25.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Carbon/Carbon.h>
#import "WLClosablePanel.h"


@implementation WLClosablePanel

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
