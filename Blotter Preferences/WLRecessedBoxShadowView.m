//
//  WLRecessedBoxShadowView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLRecessedBoxShadowView.h"
#import "WLRecessedBoxShadowLayer.h"


@implementation WLRecessedBoxShadowView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        [self setLayer:[WLRecessedBoxShadowLayer layer]];
        [self setWantsLayer:YES];
    }
    return self;
}

@end
