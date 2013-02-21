//
//  WLApplicationPreferencesWindow.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.02.13.
//  Copyright (c) 2013 WireLoad. All rights reserved.
//

#import "WLApplicationPreferencesWindow.h"
#import "WLApplicationPreferences.h"


@implementation WLApplicationPreferencesWindow

- (BOOL)performKeyEquivalent:(NSEvent *)anEvent
{
    BOOL isPerformed = [super performKeyEquivalent:anEvent];
    
    if (!isPerformed)
    {
        if (WLDoesEventContainShortcut(anEvent, NSCommandKeyMask | NSShiftKeyMask, kVK_ANSI_LeftBracket) ||
            WLDoesEventContainShortcut(anEvent, NSCommandKeyMask | NSAlternateKeyMask, kVK_LeftArrow))
        {
            [self.windowController showPreviousRepresentationAnimated:YES];
            isPerformed = YES;
        }
        else if (WLDoesEventContainShortcut(anEvent, NSCommandKeyMask | NSShiftKeyMask, kVK_ANSI_RightBracket) ||
                 WLDoesEventContainShortcut(anEvent, NSCommandKeyMask | NSAlternateKeyMask, kVK_RightArrow))
        {
            [self.windowController showNextRepresentationAnimated:YES];
            isPerformed = YES;
        }
    }

    return isPerformed;
}

@end
