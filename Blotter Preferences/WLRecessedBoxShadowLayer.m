//
//  WLRecessedBoxShadowLayer.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 27/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLRecessedBoxShadowLayer.h"


@implementation WLRecessedBoxShadowLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        self.needsDisplayOnBoundsChange = YES;
        _backgroundImages = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < 9; i++)
        {
            NSString *fileName = [NSString stringWithFormat:@"positioning-border-%d", i + 1];
            NSImage *img = [[NSImage alloc] initWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForImageResource:fileName]];
            [_backgroundImages addObject:img];
            [img release];
        }
    }
    return self;
}

- (void)dealloc
{
    [_backgroundImages release];
    [super dealloc];
}

- (void)drawInContext:(CGContextRef)aContext
{
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:gc];
    NSDrawNinePartImage(NSRectFromCGRect(self.bounds),
                        [_backgroundImages objectAtIndex:0],
                        [_backgroundImages objectAtIndex:1],
                        [_backgroundImages objectAtIndex:2],
                        [_backgroundImages objectAtIndex:3],
                        [_backgroundImages objectAtIndex:4],
                        [_backgroundImages objectAtIndex:5],
                        [_backgroundImages objectAtIndex:6],
                        [_backgroundImages objectAtIndex:7],
                        [_backgroundImages objectAtIndex:8],
                        NSCompositeSourceOver,
                        1.0f,
                        NO);
    [NSGraphicsContext restoreGraphicsState];
}

@end
