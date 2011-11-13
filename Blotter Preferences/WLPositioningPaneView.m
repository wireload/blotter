//
//  WLPositioningPaneView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLPositioningPaneView.h"

@implementation WLPositioningPaneView

- (NSView *)hitTest:(NSPoint)aPoint
{
    NSView *view = [super hitTest:aPoint];
    if (view == self)
        return _calendarWindowArrangementView;
    else
        return view;
}

@end
