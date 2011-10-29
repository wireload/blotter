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
        
        self.bounds = CGRectMake(0, 0, 1 + upperLeftSize.width + lowerRightSize.width, 1 + upperLeftSize.height + lowerRightSize.height);
        
        drawer = aDrawer;
        for (int i = 0; i < 9; i++) {
            CALayer *subLayer = [CALayer layer];
            subLayer.magnificationFilter = kCAFilterLinear;
            subLayer.minificationFilter = kCAFilterLinear;
            subLayer.autoresizingMask = 0;
            subLayer.edgeAntialiasingMask = 0;
            CGRect frame = CGRectMake(0, 0, 1, 1);
            switch(i % 3) {
                case 0:
                    subLayer.autoresizingMask |= kCALayerMaxXMargin;
                    subLayer.edgeAntialiasingMask |= kCALayerLeftEdge;
                    frame.size.width = upperLeftSize.width;
                    break;
                case 1:
                    subLayer.autoresizingMask |= kCALayerWidthSizable;
                    frame.origin.x = upperLeftSize.width;
                    break;
                case 2:
                    subLayer.autoresizingMask |= kCALayerMinXMargin;
                    subLayer.edgeAntialiasingMask |= kCALayerRightEdge;                
                    frame.origin.x = upperLeftSize.width + 1;
                    frame.size.width = lowerRightSize.width;
                    break;
            }
            if (i < 3) {
                subLayer.autoresizingMask |= kCALayerMaxYMargin;
                subLayer.edgeAntialiasingMask |= kCALayerBottomEdge;     
                frame.size.height = lowerRightSize.height;
            } else if (i < 6) {
                subLayer.autoresizingMask |= kCALayerHeightSizable;
                frame.origin.y = lowerRightSize.height;
            } else {
                subLayer.autoresizingMask |= kCALayerMinYMargin;
                subLayer.edgeAntialiasingMask |= kCALayerTopEdge;                
                frame.origin.y = lowerRightSize.height + 1;
                frame.size.height = upperLeftSize.height;
            }           
            subLayer.frame = frame;

            [self addSublayer:subLayer];
        }
        
        [self _updateSublayerImages];
        //[self setNeedsDisplay];
    }
    return self;
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
