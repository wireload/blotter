//
//  WLCalendarMockupView.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/13/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import "WLCalendarMockupView.h"


@implementation WLCalendarMockupView

#pragma mark NSView

- (BOOL)wantsUpdateLayer
{
    return YES;
}

- (void)updateLayer
{
    static const CGFloat BorderWidth = 2.0;

    self.layer.borderWidth = BorderWidth;
    self.layer.borderColor = [NSColor.blackColor colorWithAlphaComponent:0.75].CGColor;
    self.layer.backgroundColor = [NSColor.blackColor colorWithAlphaComponent:0.25].CGColor;
    self.layer.cornerRadius = 5.0;
    self.layer.masksToBounds = YES;
}

@end
