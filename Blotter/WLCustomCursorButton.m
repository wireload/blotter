//
//  NSCustomCursorButton.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 03.04.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLCustomCursorButton.h"


@implementation WLCustomCursorButton

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        _cursorTrackingArea = [[self makeCursorTrackingArea] retain];
        [self addTrackingArea:_cursorTrackingArea];
    }
    return self;
}

- (void)dealloc
{
    [cursor release];
    [_cursorTrackingArea release];
    [super dealloc];
}


#pragma mark Properties
@synthesize cursor;


#pragma mark Methods

- (NSTrackingArea *)makeCursorTrackingArea
{
    NSTrackingAreaOptions trackingOptions = NSTrackingCursorUpdate | NSTrackingActiveInActiveApp;
    NSTrackingArea *cursorTrackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                                      options:trackingOptions
                                                                        owner:self
                                                                     userInfo:nil];
    return [cursorTrackingArea autorelease];
}


#pragma mark NSButton

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self removeTrackingArea:_cursorTrackingArea];
    [_cursorTrackingArea release];
    _cursorTrackingArea = [[self makeCursorTrackingArea] retain];
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
