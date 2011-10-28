//
//  WLRecessedBoxShadowLayer.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 27/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSColor+CGColor.h"
#import "WLRecessedBoxShadowLayer.h"

@implementation WLRecessedBoxShadowLayer

- (id)init
{
    if (self = [super init]) {
        self.needsDisplayOnBoundsChange = YES;

        NSMutableArray *r = [NSMutableArray array];
        for (int i = 0; i < 9; i++) {
            NSString *fileName = [NSString stringWithFormat:@"positioning-border-%d", i + 1];
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:fileName ofType:@"png"];
            [r addObject:[[NSImage alloc] initWithContentsOfFile:path]];
        }
        
        backgroundImages = [r retain];
    }

    return self;
}

- (void)drawInContext:(CGContextRef)aContext
{
    NSGraphicsContext *gc = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO]; 
    [NSGraphicsContext saveGraphicsState]; 
    [NSGraphicsContext setCurrentContext:gc];
    NSDrawNinePartImage(NSRectFromCGRect(self.bounds),
                        [backgroundImages objectAtIndex:0],
                        [backgroundImages objectAtIndex:1],
                        [backgroundImages objectAtIndex:2],
                        [backgroundImages objectAtIndex:3],
                        nil,
                        [backgroundImages objectAtIndex:5],
                        [backgroundImages objectAtIndex:6],
                        [backgroundImages objectAtIndex:7],
                        [backgroundImages objectAtIndex:8],
                        NSCompositeSourceOver,
                        1.0,
                        NO);
    [NSGraphicsContext restoreGraphicsState];
}

@end
