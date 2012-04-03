//
//  NSCustomCursorButton.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WLCustomCursorButton : NSButton
{
    NSCursor *cursor;

    NSTrackingArea *_cursorTrackingArea;
}

@property (nonatomic, retain) NSCursor *cursor;

- (NSTrackingArea *)makeCursorTrackingArea;

@end
