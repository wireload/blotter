//
//  WLCalendarWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 01.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum
{
    WLFinderLevelState,
    WLLevelingUpState,
    WLFloatingLevelState,
    WLLevelingDownState
} WLCalendarWindowState;

/*!
 @abstract      Borderless window that draws custom background.
 @discussion    Default contentView is flipped.
 @classdesign   You SHOULD use -init to initialize.
 @coclass       WLCalendarWindowBackgroundView
 @ownership     WLCalendarWindowController
 */
@interface WLCalendarWindow : NSWindow {
    NSView *_realContentView;
    
    WLCalendarWindowState state;
    BOOL _didWarmUp;
}

@property (nonatomic) WLCalendarWindowState state;

- (NSView *)realContentView;

- (void)levelUp;
- (void)levelDown;

@end
