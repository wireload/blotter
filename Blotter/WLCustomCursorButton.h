//
//  NSCustomCursorButton.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @abstract  Allows a user to customize cursor for a button.
 */
@interface WLCustomCursorButton : NSButton
{
    NSCursor *cursor;

    NSTrackingArea *_cursorTrackingArea;
}

/*!
 @abstract      Specifies cursor of the button.
 @discussion    Sends -cursorUpdate:nil to the button when changes.
 */
@property (nonatomic, retain) NSCursor *cursor;

/*!
 @abstract      Returns cursor tracking area.
 @discussion    Automatically sent in -updateTrackingAreas:
 */
- (NSTrackingArea *)makeCursorTrackingArea;

@end
