//
//  WLLayoutTasksView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLLayoutTasksView.h"
#import "WLLayoutCalendarWindowView.h"


@implementation WLLayoutTasksView

#pragma mark NSView

- (void)drawRect:(NSRect)aDirtyRect
{
    [[NSColor darkGrayColor] setFill];
    NSRectFill([self bounds]);
}

- (NSInteger)tag
{
    return WLLayoutTasksViewTag;
}

@end
