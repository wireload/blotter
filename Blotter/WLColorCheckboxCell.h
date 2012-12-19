//
//  ColorCheckboxCell.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
    @abstract    Checkbox with color background.
    @discussion  Reverse engineered from CalColorCheckboxCell (used by iCal).
*/
@interface WLColorCheckboxCell : NSButtonCell

+ (NSImage *)checkboxCellImageWithColor:(NSColor *)aColor state:(NSInteger)aState;

- (void)setButtonColor:(NSColor *)newColor;

@end
