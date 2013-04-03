//
//  NSImage+WLHiDPIDrawing.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 26.03.13.
//  Copyright (c) 2013 Wireload. All rights reserved.
//

#import "NSImage+WLHiDPIDrawing.h"


@implementation NSImage (WLHiDPIDrawing)

+ (NSImage *)WL_imageWithSize:(NSSize)aSize flipped:(BOOL)anIsFlipped drawingHandler:(WLImageDrawingHandler)aDrawingHandler
{
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
    {
        NSBitmapImageRep *x1 = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                       pixelsWide:(NSInteger)ceil(aSize.width)
                                                                       pixelsHigh:(NSInteger)ceil(aSize.height)
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:4
                                                                         hasAlpha:YES
                                                                         isPlanar:NO
                                                                   colorSpaceName:NSCalibratedRGBColorSpace
                                                                      bytesPerRow:0
                                                                     bitsPerPixel:0];
        [x1 setSize:aSize];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:x1]];
        aDrawingHandler(CGRectMake(0.0, 0.0, aSize.width, aSize.height));
        [NSGraphicsContext restoreGraphicsState];

        NSBitmapImageRep *x2 = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                       pixelsWide:(NSInteger)ceil(aSize.width * 2.0)
                                                                       pixelsHigh:(NSInteger)ceil(aSize.height * 2.0)
                                                                    bitsPerSample:8
                                                                  samplesPerPixel:4
                                                                         hasAlpha:YES
                                                                         isPlanar:NO
                                                                   colorSpaceName:NSCalibratedRGBColorSpace
                                                                      bytesPerRow:0
                                                                     bitsPerPixel:0];
        [x2 setSize:aSize];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:x2]];
        aDrawingHandler(CGRectMake(0.0, 0.0, aSize.width, aSize.height));
        [NSGraphicsContext restoreGraphicsState];

        NSImage *i = [[NSImage alloc] initWithSize:aSize];
        [i addRepresentations:@[x1, x2]];
        return i;
    }
    else
        return [NSImage imageWithSize:aSize flipped:anIsFlipped drawingHandler:aDrawingHandler];
}

@end
