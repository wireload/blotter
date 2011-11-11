//
//  WLGlassHudDatePicker.m
//  Blotter
//
//  Created by Ilya Kulakov on 27.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudDatePicker.h"


@implementation WLGlassHudDatePicker

- (id<WLGlassHudDatePickerCellDelegate>)delegate
{
    return (id<WLGlassHudDatePickerCellDelegate>)[super delegate];
}

- (void)setDelegate:(id<WLGlassHudDatePickerCellDelegate>)newDelegate
{
    [super setDelegate:newDelegate];
}

- (BOOL)becomeFirstResponder
{
    BOOL isBecome = [super becomeFirstResponder];
    if (isBecome && [[self delegate] respondsToSelector:@selector(datePickerCellDidBecomeFirstResponder:)])
        [[self delegate] datePickerCellDidBecomeFirstResponder:[self cell]];
    return isBecome;
}

- (BOOL)resignFirstResponder
{
    BOOL isResigned = [super resignFirstResponder];
    if (isResigned && [[self delegate] respondsToSelector:@selector(datePickerCellDidResignFirstResponder:)])
        [[self delegate] datePickerCellDidResignFirstResponder:[self cell]];
    return isResigned;
}

@end
