//
//  WLCalendarWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BLFadeController.h"


/*!
 @abstract      Borderless window that draws custom background.
 @classdesign   You SHOULD use -init to initialize.
 @ownership     WLCalendarWindowController
 */
@interface WLCalendarWindow : NSWindow {
}

/*!
 @abstract Returns bounds in contentView's coordinates where subviews SHOULD be placed.
 */
- (NSRect)contentViewBounds;

@end
