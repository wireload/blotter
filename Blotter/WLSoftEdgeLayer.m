//
//  WLSoftEdgeLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 22.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLSoftEdgeLayer.h"


static NSString* const _WLTopEdgeLayerKey = @"top";

static NSString* const _WLMiddleLayerKey = @"middle";

static NSString* const _WLBottomEdgeLayerKey = @"bottom";


@implementation WLSoftEdgeLayer

- (id)init
{
    self = [super init];
    if (self != nil) {
        CAGradientLayer *topEdge = [CAGradientLayer layer];
        topEdge.colors = [NSArray arrayWithObjects:(id)[[NSColor clearColor] WL_CGColor], (id)[[NSColor blackColor] WL_CGColor], nil];
        [self addSublayer:topEdge];
        [self setValue:topEdge forKey:_WLTopEdgeLayerKey];

        CALayer *middle = [CALayer layer];
        middle.backgroundColor = [[NSColor blackColor] WL_CGColor];
        [self addSublayer:middle];
        [self setValue:middle forKey:_WLMiddleLayerKey];

        CAGradientLayer *bottomEdge = [CAGradientLayer layer];
        bottomEdge.colors = [NSArray arrayWithObjects:(id)[[NSColor blackColor] WL_CGColor], (id)[[NSColor clearColor] WL_CGColor], nil];
        [self addSublayer:bottomEdge];
        [self setValue:bottomEdge forKey:_WLBottomEdgeLayerKey];
    }
    return self;
}


#pragma mark Properties
@dynamic edgeHeight;


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqual:@"edgeHeight"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqual:@"edgeHeight"])
        return [NSNumber numberWithFloat:15.0f];
    else if ([aKey isEqual:@"geometryFlipped"])
        return [NSNumber numberWithBool:YES];
    else
        return [super defaultValueForKey:aKey];
}

- (void)layoutSublayers
{
    [CATransaction WL_performWithDisabledActions:^(void) {
        CGFloat h = self.edgeHeight;
        if (self.bounds.size.height < 2 * h)
            h = floorf(self.bounds.size.height / 2);

        CAGradientLayer *topEdge = [self valueForKey:_WLTopEdgeLayerKey];
        NSParameterAssert(topEdge != nil);
        topEdge.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), self.bounds.size.width, h);

        CALayer *middle = [self valueForKey:_WLMiddleLayerKey];
        NSParameterAssert(middle != nil);
        middle.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds) + h, self.bounds.size.width, self.bounds.size.height - 2 * h);

        CAGradientLayer *bottomEdge = [self valueForKey:_WLBottomEdgeLayerKey];
        NSParameterAssert(bottomEdge != nil);
        bottomEdge.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMaxY(self.bounds) - h, self.bounds.size.width, h);
    }];
}

@end
