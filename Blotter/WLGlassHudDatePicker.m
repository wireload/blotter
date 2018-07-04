//
//  WLGlassHudDatePicker.m
//  Blotter
//
//  Created by Ilya Kulakov on 27.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudDatePicker.h"


@implementation WLGlassHudDatePicker

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.textColor = [NSColor whiteColor];
}

- (id<WLGlassHudDatePickerCellDelegate>)delegate
{
    return (id<WLGlassHudDatePickerCellDelegate>)super.delegate;
}

- (void)setDelegate:(id<WLGlassHudDatePickerCellDelegate>)newDelegate
{
    super.delegate = newDelegate;
}

- (BOOL)becomeFirstResponder
{
    BOOL isBecome = [super becomeFirstResponder];
    if (isBecome)
    {
        if ([[self delegate] respondsToSelector:@selector(datePickerCellDidBecomeFirstResponder:)])
            [[self delegate] datePickerCellDidBecomeFirstResponder:self.cell];
        self.textColor = [NSColor blackColor];
    }
    return isBecome;
}

- (BOOL)resignFirstResponder
{
    BOOL isResigned = [super resignFirstResponder];
    if (isResigned)
    {
        if ([[self delegate] respondsToSelector:@selector(datePickerCellDidResignFirstResponder:)])
            [[self delegate] datePickerCellDidResignFirstResponder:self.cell];
        self.textColor = [NSColor whiteColor];
    }
    return isResigned;
}

@end
