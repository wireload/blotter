//
//  WLRoundedImageView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLRoundedAquaImageView.h"


@implementation WLRoundedAquaImageView

- (id)initWithFrame:(NSRect)aFrameRect
{
    self = [super initWithFrame:aFrameRect];
    if (self != nil)
    {
        CALayer *l = [CALayer layer];
        l.contents = [[NSImage alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForImageResource:@"Recreated-Aqua"]];
        l.cornerRadius = 1.25f;
        l.masksToBounds = YES;
        l.opaque = YES;
        [self setLayer:l];
        [self setWantsLayer:YES];
    }
    return self;
}

@end
