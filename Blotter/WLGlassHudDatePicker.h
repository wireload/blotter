//
//  WLGlassHudDatePicker.h
//  Blotter
//
//  Created by Ilya Kulakov on 27.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol WLGlassHudDatePickerCellDelegate;

@interface WLGlassHudDatePicker : NSDatePicker

- (id<WLGlassHudDatePickerCellDelegate>)delegate;
- (void)setDelegate:(id<WLGlassHudDatePickerCellDelegate>)newDelegate;

@end


@protocol WLGlassHudDatePickerCellDelegate <NSDatePickerCellDelegate>;
@optional
- (void)datePickerCellDidBecomeFirstResponder:(NSDatePickerCell *)aDatePickerCell;

- (void)datePickerCellDidResignFirstResponder:(NSDatePickerCell *)aDatePickerCell;

@end
