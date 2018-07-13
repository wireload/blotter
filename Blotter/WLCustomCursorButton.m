//
//  NSCustomCursorButton.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCustomCursorButton.h"


@implementation WLCustomCursorButton
{
    NSTrackingArea *_cursorTrackingArea;
}

- (instancetype)initWithFrame:(NSRect)aFrameRect
{
    if (self = [super initWithFrame:aFrameRect])
    {
        _cursorTrackingArea = [self makeCursorTrackingArea];
        [self addTrackingArea:_cursorTrackingArea];
    }

    return self;
}


#pragma mark Methods

- (NSTrackingArea *)makeCursorTrackingArea
{
    NSTrackingAreaOptions trackingOptions = NSTrackingCursorUpdate | NSTrackingActiveInActiveApp;
    NSTrackingArea *cursorTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                      options:trackingOptions
                                                                        owner:self
                                                                     userInfo:nil];
    return cursorTrackingArea;
}


#pragma mark NSButton

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self removeTrackingArea:_cursorTrackingArea];
    _cursorTrackingArea = [self makeCursorTrackingArea];
    [self addTrackingArea:_cursorTrackingArea];
}


#pragma mark NSResponder

- (void)cursorUpdate:(NSEvent *)anEvent
{
    if (self.cursor != nil)
        [self.cursor set];
    else
        [[NSCursor arrowCursor] set];
}

@end
