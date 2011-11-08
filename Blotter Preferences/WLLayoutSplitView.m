//
//  WLLayoutSplitView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLLayoutSplitView.h"


@implementation WLLayoutSplitView

- (NSObject<WLLayoutSplitViewDelegate> *)delegate
{
    return (NSObject<WLLayoutSplitViewDelegate> *)[super delegate];
}

- (void)setDelegate:(NSObject <WLLayoutSplitViewDelegate> *)delegate
{
    [super setDelegate:delegate];
}


#pragma mark NSView

- (void)mouseDown:(NSEvent *)anEvent
{
    if ([[self delegate] respondsToSelector:@selector(splitViewWillTrackMouse:)])
        [[self delegate] splitViewWillTrackMouse:self];
    [super mouseDown:anEvent];
    if ([[self delegate] respondsToSelector:@selector(splitViewDidTrackMouse:)])
        [[self delegate] splitViewDidTrackMouse:self];
}

@end
