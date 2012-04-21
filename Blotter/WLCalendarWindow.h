//
//  WLCalendarWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WLCalendarWindowBackgroundView.h"


/*!
 @abstract      Borderless window that draws custom background.
 @discussion    Default contentView is flipped.
 Overrides -cancelOperation: and forwards it directly to NSApp's delegate if it implements this method.
 Otherwise message is forwarded to super.
 @classdesign   You SHOULD use -init to initialize.
 @coclass       WLCalendarWindowBackgroundView
 @ownership     WLCalendarWindowController
 */
@interface WLCalendarWindow : NSWindow <NSAnimationDelegate>
{
    NSView *_fakeContentView;
    CIFilter *_blurInputFilter;
    CIFilter *_blurOutputFilter;
}

- (WLCalendarWindowBackgroundView *)realContentView;

- (CGImageRef)newCGImageOfScreenBelowWindow;

- (CIImage *)blurredBackgroundImage;

@end
