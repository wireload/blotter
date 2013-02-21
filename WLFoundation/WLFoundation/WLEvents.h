//
//  WLEvents.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @abstract  Tests whetehr a given key event matches the shortcut.
 @see       HIToolbox/Events.h
 */
BOOL WLDoesEventContainShortcut(NSEvent *event, NSUInteger shortcutFlags, int shortcutKey);
