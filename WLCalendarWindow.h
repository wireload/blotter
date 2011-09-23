//
//  WLCalendarWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 @abstract      Borderless window that draws custom background.
 @discussion    Default contentView is flipped.
 @classdesign   You SHOULD use -init to initialize.
 @coclass       WLCalendarWindowFrameView
 @ownership     WLCalendarWindowController
 */
@interface WLCalendarWindow : NSWindow {
    NSView *_realContentView;
}

- (NSView *)realContentView;

@end
