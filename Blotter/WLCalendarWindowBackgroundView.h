//
//  WLCalendarWindowBackgroundView.h
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 @abstract      Draws background of WLCalendarWindow.
 @discussion    The role of this class is similar to the role of the private NSThemeFrame class.
 CAN have only 1 subview.
 @ownership     WLCalendarWindow
 */
@interface WLCalendarWindowBackgroundView : NSView
{
    dispatch_once_t _didWarmUp;
}

+ (NSRect)contentRectForFrameRect:(NSRect)aFrame;

+ (NSRect)frameRectForContentRect:(NSRect)aContentRect;

+ (NSRect)glassRectForBounds:(NSRect)aBounds;

@end
