//
//  WLNinePartBlockLayer.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 28/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WLNinePartBlockLayer.h"


@implementation WLNinePartBlockLayer

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSMutableArray *a = [[NSMutableArray alloc] initWithCapacity:9];
        for (NSUInteger i = 0; i < 9; ++i)
        {
            CALayer *subLayer = [CALayer layer];
            subLayer.magnificationFilter = kCAFilterLinear;
            subLayer.minificationFilter = kCAFilterLinear;
            subLayer.autoresizingMask = 0;
            subLayer.edgeAntialiasingMask = 0;
            subLayer.delegate = self;
            [a addObject:subLayer];
            [self addSublayer:subLayer];
        }
        _sublayers = a;
    }
    return self;
}

-(void)dealloc
{
    if (_contents != NULL)
        CGImageRelease(_contents);
    [_sublayers release];
    [super dealloc];
}


#pragma mark Properties
@dynamic edgeSize;


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"edgeSize"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)layoutSublayers
{
    CGSize size = [self bounds].size;
    CGFloat middleWidth = fmaxf(1.0f, size.width - 2 * self.edgeSize.width);
    CGFloat middleHeight = fmaxf(1.0f, size.height - 2 * self.edgeSize.height);
    for (NSUInteger i = 0; i < 9; ++i)
    {
        CALayer *sublayer = [_sublayers objectAtIndex:i];
        CGRect frame = CGRectMake(0.0f, 0.0f, middleWidth, middleHeight);
        switch(i % 3)
        {
            case 0:
                frame.size.width = self.edgeSize.width;
                break;
            case 1:
                frame.origin.x = self.edgeSize.width;
                break;
            case 2:
                frame.origin.x = self.edgeSize.width + middleWidth;
                frame.size.width = self.edgeSize.width;
                break;
        }
        if (i < 3)
        {
            frame.size.height = self.edgeSize.height;
        }
        else if (i < 6)
        {
            frame.origin.y = self.edgeSize.height;
        }
        else if (i < 9)
        {
            frame.origin.y = self.edgeSize.height + middleHeight;
            frame.size.height = self.edgeSize.height;
        }
        sublayer.frame = frame;
    }
}

- (void)displayLayer:(CALayer *)aLayer
{
    NSAssert(_contents != NULL, @"_contents must be initialized at this point");
    
    NSInteger i = [_sublayers indexOfObjectIdenticalTo:aLayer];
    if (i == NSNotFound)
    {
        NSLog(@"Unknown sublayer: %@", aLayer);
        return;
    }
    CALayer *sublayer = [_sublayers objectAtIndex:i];
    CGRect sliceFrame = [sublayer frame];
    if (!self.geometryFlipped)
        sliceFrame.origin.y = self.bounds.size.height - sliceFrame.size.height - sliceFrame.origin.y;
    CGImageRef sliceImage = CGImageCreateWithImageInRect(_contents, sliceFrame); //CGBitmapContextCreateImage(sliceImageContext);
    if (sliceImage != NULL)
    {
        sublayer.contents = (id)sliceImage;
        CGImageRelease(sliceImage);
    }
}

- (void)display
{
    if (_contents != NULL)
        CGImageRelease(_contents);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace != NULL)
    {
        CGContextRef imageContext = CGBitmapContextCreate(NULL,
                                                          self.bounds.size.width,
                                                          self.bounds.size.height,
                                                          8,
                                                          4 * self.bounds.size.width,
                                                          colorSpace,
                                                          kCGImageAlphaPremultipliedFirst);
        if (imageContext != NULL)
        {
            self.drawer(imageContext, self, self.bounds);
            _contents = CGBitmapContextCreateImage(imageContext);
            CGContextRelease(imageContext);
        }
        CGColorSpaceRelease(colorSpace);
    }
    [_sublayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
    self.contents = nil;
}

@end
