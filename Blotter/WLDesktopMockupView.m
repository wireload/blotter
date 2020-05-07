//
//  WLDesktopMockupView.m
//  Blotter
//
//  Created by Ilya Kulakov on 3/13/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import "WLDesktopMockupView.h"


@implementation WLDesktopMockupView

#pragma mark Methods

- (NSImageView *)makeDesktopView
{
    NSImageView *v = [NSImageView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.image = [NSImage imageNamed:@"preferences-wallpaper"];
    v.editable = NO;
    v.imageScaling = NSImageScaleAxesIndependently;
    v.imageAlignment = NSImageAlignCenter;
    v.imageFrameStyle = NSImageFrameNone;
    return v;
}

- (NSImageView *)makeShadowView
{
    NSImageView *v = [NSImageView new];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.image = [NSImage imageNamed:@"recessed-box-shadow"];
    v.editable = NO;
    v.imageScaling = NSImageScaleAxesIndependently;
    v.imageAlignment = NSImageAlignCenter;
    v.imageFrameStyle = NSImageFrameNone;
    return v;
}

#pragma mark WLLayerBackedView

- (void)prepareForBackingLayer
{
    [super prepareForBackingLayer];
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

    self.canDrawSubviewsIntoLayer = YES;
    self.layer.cornerRadius = 1.5;

    NSImageView *desktopView = [self makeDesktopView];
    [self addSubview:desktopView];

    NSImageView *shadowView = [self makeShadowView];
    [self addSubview:shadowView];

    [NSLayoutConstraint activateConstraints:@[
        [shadowView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [shadowView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [shadowView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [shadowView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:1.0],

        [desktopView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [desktopView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [desktopView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
        [desktopView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

#pragma mark NSView

+ (BOOL)requiresConstraintBasedLayout
{
    return YES;
}

- (NSEdgeInsets)alignmentRectInsets
{
    return NSEdgeInsetsMake(0.0, 0.0, 1.0, 0.0);
}

@end
