//
//  WLEvents.m
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad Inc. All rights reserved.
//

#import "WLEvents.h"


BOOL WLDoesEventContainShortcut(NSEvent *event, NSUInteger shortcutFlags, int shortcutKey)
{
    static NSUInteger FlagsMask = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
    
    NSUInteger eventFlags = [event modifierFlags];
    unsigned short eventKeyCode = [event keyCode];
    
    BOOL doesFlagsMatch = (eventFlags & (FlagsMask ^ shortcutFlags)) == 0 && (eventFlags & shortcutFlags);
    return (doesFlagsMatch || shortcutFlags == 0) && eventKeyCode == shortcutKey;
}
