//
//  WLGraphics.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"


void WLRecessedBoxShadow(NSRect frame)
{
    static dispatch_once_t onceToken;
    static NSImage *Images[9];
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"net.wireload.blotter.mac.framework"];
        Images[0] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-top-left"]];
        Images[1] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-top"]];
        Images[2] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-top-right"]];
        Images[3] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-middle-left"]];
        Images[4] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-middle"]];
        Images[5] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-middle-right"]];
        Images[6] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-bottom-left"]];
        Images[7] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-bottom"]];
        Images[8] = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"recessed-box-shadow-bottom-right"]];
    });

    [NSGraphicsContext saveGraphicsState];
    NSDrawNinePartImage(frame,
                        Images[0],
                        Images[1],
                        Images[2],
                        Images[3],
                        Images[4],
                        Images[5],
                        Images[6],
                        Images[7],
                        Images[8],
                        NSCompositeSourceOver,
                        1.0f,
                        NO);
    [NSGraphicsContext restoreGraphicsState];
}

#define NSRectFromSize(size) (NSMakeRect(0, 0, (size).width, (size).height))

/**
 Like NSDrawNinePartImage but scale the middle parts instead of tiling them. This allows some simple gradients
 from edge to edge as long as the detail is such that it scales up and down well with bilinear filtering.
 */
void WLDrawScaledNinePartImage(NSRect bounds,
                               NSImage *topLeftCorner,
                               NSImage *topEdgeFill,
                               NSImage *topRightCorner,
                               NSImage *leftEdgeFill,
                               NSImage *centerFill,
                               NSImage *rightEdgeFill,
                               NSImage *bottomLeftCorner,
                               NSImage *bottomEdgeFill,
                               NSImage *bottomRightCorner,
                               NSCompositingOperation op,
                               CGFloat alphaFraction,
                               BOOL flipped)
{
    NSSize topLeftSize = [topLeftCorner size];
    NSSize bottomRightSize = [bottomRightCorner size];
    
    // If we are drawing in an area in which the corner parts don't fit, remove pixels
    // from the centre instead of from the edges (and avoid overlapping). This looks a
    // lot better when a border style 9-part image shrinks, assuming the top and bottom
    // and left/right are symmetrical and can fit together at smaller sizes. In particular
    // this is true for your layout views in the layout preferences.
    CGFloat excessWidth = topLeftSize.width + bottomRightSize.width - bounds.size.width;
    CGFloat excessHeight = topLeftSize.height + bottomRightSize.height - bounds.size.height;
    NSPoint topLeftOffset = NSMakePoint(0, 0);
    NSPoint bottomRightOffset = NSMakePoint(0, 0);
    
    if (excessWidth > 0) {
        topLeftSize.width -= floorf(excessWidth / 2.0);
        bottomRightOffset.x = ceilf(excessWidth / 2.0);
        bottomRightSize.width -= bottomRightOffset.x;
    }
    
    if (excessHeight > 0) {
        topLeftOffset.y = floorf(excessHeight / 2.0);;
        topLeftSize.height -= topLeftOffset.y;
        bottomRightOffset.y = ceilf(excessHeight / 2.0);
        bottomRightSize.height -= bottomRightOffset.y;
    }
    
    CGFloat leftX = 0;
    CGFloat midX = topLeftSize.width;
    CGFloat rightX = bounds.size.width - bottomRightSize.width;
    CGFloat midWidth = rightX - midX;

    CGFloat bottomY = flipped ? bounds.size.height - bottomRightSize.height : 0;
    CGFloat midY = flipped ? topLeftSize.height : bottomRightSize.height;
    CGFloat topY = flipped ? 0 : bounds.size.height - topLeftSize.height;
    CGFloat midHeight = flipped ? bottomY - midY : topY - midY;
    
    BOOL    drawMiddleX = midWidth > 0;
    BOOL    drawMiddleY = midHeight > 0;

    [topLeftCorner drawInRect:NSMakeRect(leftX, topY, topLeftSize.width, topLeftSize.height) 
                     fromRect:NSMakeRect(0, flipped ? topLeftOffset.y : 0, topLeftSize.width, topLeftSize.height)
                    operation:op 
                     fraction:alphaFraction 
               respectFlipped:YES 
                        hints:nil];
    
    if (drawMiddleX)
        [topEdgeFill drawInRect:NSMakeRect(midX, topY, midWidth, topLeftSize.height) 
                       fromRect:NSMakeRect(0, flipped ? topLeftOffset.y : 0, topEdgeFill.size.width, topLeftSize.height)
                      operation:op 
                       fraction:alphaFraction 
                 respectFlipped:YES 
                          hints:nil];
    
    [topRightCorner drawInRect:NSMakeRect(rightX, topY, bottomRightSize.width, topLeftSize.height) 
                      fromRect:NSMakeRect(bottomRightOffset.x, flipped ? topLeftOffset.y : 0, bottomRightSize.width, topLeftSize.height)
                     operation:op 
                      fraction:alphaFraction 
                respectFlipped:YES 
                         hints:nil];
    
    if (drawMiddleY)
    {
        [leftEdgeFill drawInRect:NSMakeRect(leftX, midY, topLeftSize.width, midHeight) 
                        fromRect:NSRectFromSize([leftEdgeFill size]) 
                       operation:op 
                        fraction:alphaFraction 
                  respectFlipped:YES 
                           hints:nil];
        if (drawMiddleX) 
            [centerFill drawInRect:NSMakeRect(midX, midY, midWidth, midHeight) 
                          fromRect:NSRectFromSize([centerFill size]) 
                         operation:op 
                          fraction:alphaFraction 
                    respectFlipped:YES 
                             hints:nil];
        [rightEdgeFill drawInRect:NSMakeRect(rightX, midY, bottomRightSize.width, midHeight) 
                         fromRect:NSRectFromSize([rightEdgeFill size]) 
                        operation:op 
                         fraction:alphaFraction 
                   respectFlipped:YES 
                            hints:nil];
    }
    
    [bottomLeftCorner drawInRect:NSMakeRect(leftX, bottomY, topLeftSize.width, bottomRightSize.height) 
                        fromRect:NSMakeRect(0, !flipped ? bottomRightOffset.y : 0, topLeftSize.width, bottomRightSize.height) 
                       operation:op 
                        fraction:alphaFraction 
                  respectFlipped:YES 
                           hints:nil];
    
    if (drawMiddleX)
        [bottomEdgeFill drawInRect:NSMakeRect(midX, bottomY, midWidth, bottomRightSize.height) 
                          fromRect:NSMakeRect(0, !flipped ? bottomRightOffset.y : 0, bottomEdgeFill.size.width, bottomRightSize.height)
                         operation:op 
                          fraction:alphaFraction 
                    respectFlipped:YES 
                             hints:nil];
    
    [bottomRightCorner drawInRect:NSMakeRect(rightX, bottomY, bottomRightSize.width, bottomRightSize.height) 
                         fromRect:NSMakeRect(bottomRightOffset.x, !flipped ? bottomRightOffset.y : 0, bottomRightSize.width, bottomRightSize.height)
                        operation:op 
                         fraction:alphaFraction 
                   respectFlipped:YES 
                            hints:nil];
}