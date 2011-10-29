//
//  WLNinePartBlockLayer.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 28/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLNinePartBlockLayer.h"
#import "NSColor+CGColor.h"

@implementation WLNinePartBlockLayer

- (id)initWithDrawer:(WLImageDrawer)aDrawer upperLeftSize:(CGSize)anUpperLeftSize lowerRightSize:(CGSize)aLowerRightSize {
    if (self = [super init]) {
        upperLeftSize = anUpperLeftSize;
        lowerRightSize = aLowerRightSize;
        
        drawer = aDrawer;
        for (int i = 0; i < 9; i++) {
            CALayer *subLayer = [CALayer layer];
            subLayer.magnificationFilter = kCAFilterLinear;
            subLayer.minificationFilter = kCAFilterLinear;
            subLayer.autoresizingMask = 0;
            subLayer.edgeAntialiasingMask = 0;
            switch(i % 3) {
                case 0:
                    subLayer.edgeAntialiasingMask |= kCALayerLeftEdge;
                    break;
                case 2:
                    subLayer.edgeAntialiasingMask |= kCALayerRightEdge;                
                    break;
            }
            if (i < 3) {
                subLayer.edgeAntialiasingMask |= kCALayerBottomEdge;     
            } else if (i >= 6) {
                subLayer.edgeAntialiasingMask |= kCALayerTopEdge;                
            }           

            [self addSublayer:subLayer];
        }
        
        // Set a minimal size for drawing the sublayer images.
        self.bounds = CGRectMake(0, 0, 1 + upperLeftSize.width + lowerRightSize.width, 1 + upperLeftSize.height + lowerRightSize.height);
        [self layoutSublayers];
        [self _updateSublayerImages];
    }
    return self;
}

- (void)layoutSublayers
{
    int middleWidth = MAX(1, [self bounds].size.width - upperLeftSize.width - lowerRightSize.width);
    int middleHeight = MAX(1, [self bounds].size.height - upperLeftSize.height - lowerRightSize.height);
    for (int i = 0; i < 9; i++) {
        CALayer *subLayer = [[self sublayers] objectAtIndex:i];
        CGRect frame = CGRectMake(0, 0, middleWidth, middleHeight);
        switch(i % 3) {
            case 0:
                frame.size.width = upperLeftSize.width;
                break;
            case 1:
                frame.origin.x = upperLeftSize.width;
                break;
            case 2:
                frame.origin.x = upperLeftSize.width + middleWidth;
                frame.size.width = lowerRightSize.width;
                break;
        }
        if (i < 3) {
            frame.size.height = lowerRightSize.height;
        } else if (i < 6) {
            frame.origin.y = lowerRightSize.height;
        } else {
            frame.origin.y = lowerRightSize.height + middleHeight;
            frame.size.height = upperLeftSize.height;
        }           
        subLayer.frame = frame;
    }
}

- (void)_updateSublayerImages
{
    if (drawer != nil)
    {
        // Render an image with the drawer and then slice it into the pieces for the parts.
        CGSize size = CGSizeMake(1 + upperLeftSize.width + lowerRightSize.width, 1 + upperLeftSize.height + lowerRightSize.height);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef imageContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedFirst);
        drawer(imageContext);
        CGImageRef fullImage = CGBitmapContextCreateImage(imageContext);
        CGContextRelease(imageContext);
        
        // Now slice the image to the parts.
        for (int i = 0; i < 9; i++)
        {
            CALayer *sublayer = [[self sublayers] objectAtIndex:i];
            CGRect sliceFrame = [sublayer frame];
            // NSLog(@"rendering slice %d of size %@", i, NSStringFromRect(NSRectFromCGRect(sliceFrame)));
            CGContextRef sliceImageContext = CGBitmapContextCreate(NULL, sliceFrame.size.width, sliceFrame.size.height, 8, 4 * sliceFrame.size.width, colorSpace, kCGImageAlphaPremultipliedFirst);
            
            CGContextDrawImage(sliceImageContext, CGRectMake(-sliceFrame.origin.x, -sliceFrame.origin.y, size.width, size.height), fullImage);

            CGImageRef sliceImage = CGBitmapContextCreateImage(sliceImageContext);
            CGContextRelease(sliceImageContext);
            
            sublayer.contents = (id)sliceImage;
            // TODO If setNeedsDisplay is ever called on the sublayer, its contents will be overwritten.
            CGImageRelease(sliceImage);
        }
        
        CGImageRelease(fullImage);
        CGColorSpaceRelease(colorSpace);	
    }        
}

@end
