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
    CGFloat leftX = 0;
    CGFloat midX = topLeftSize.width;
    CGFloat rightX = bounds.size.width - bottomRightSize.width;
    CGFloat topY = bounds.size.height - topLeftSize.height;
    CGFloat midY = bottomRightSize.height;
    CGFloat bottomY = 0;
    
    if (flipped) {
        bottomY = topY;
        topY = 0;
    }
    
    [topLeftCorner drawInRect:NSMakeRect(leftX, topY, topLeftSize.width, topLeftSize.height) 
                     fromRect:NSRectFromSize([topLeftCorner size]) 
                    operation:op 
                     fraction:alphaFraction 
               respectFlipped:YES 
                        hints:nil];
    
    [topEdgeFill drawInRect:NSMakeRect(midX, topY, bounds.size.width - topLeftSize.width - bottomRightSize.width, topLeftSize.height) 
                   fromRect:NSRectFromSize([topEdgeFill size]) 
                  operation:op 
                   fraction:alphaFraction 
             respectFlipped:YES 
                      hints:nil];
    
    [topRightCorner drawInRect:NSMakeRect(rightX, topY, bottomRightSize.width, topLeftSize.height) 
                      fromRect:NSRectFromSize([topRightCorner size]) 
                     operation:op 
                      fraction:alphaFraction 
                respectFlipped:YES 
                         hints:nil];
    
    [leftEdgeFill drawInRect:NSMakeRect(leftX, midY, topLeftSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                    fromRect:NSRectFromSize([leftEdgeFill size]) 
                   operation:op 
                    fraction:alphaFraction 
              respectFlipped:YES 
                       hints:nil];
    
    [centerFill drawInRect:NSMakeRect(midX, midY, bounds.size.width - topLeftSize.width - bottomRightSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                  fromRect:NSRectFromSize([centerFill size]) 
                 operation:op 
                  fraction:alphaFraction 
            respectFlipped:YES 
                     hints:nil];
    
    [rightEdgeFill drawInRect:NSMakeRect(rightX, midY, bottomRightSize.width, bounds.size.height - topLeftSize.height - bottomRightSize.height) 
                     fromRect:NSRectFromSize([rightEdgeFill size]) 
                    operation:op 
                     fraction:alphaFraction 
               respectFlipped:YES 
                        hints:nil];
    
    [bottomLeftCorner drawInRect:NSMakeRect(leftX, bottomY, topLeftSize.width, bottomRightSize.height) 
                        fromRect:NSRectFromSize([bottomLeftCorner size]) 
                       operation:op 
                        fraction:alphaFraction 
                  respectFlipped:YES 
                           hints:nil];
    
    [bottomEdgeFill drawInRect:NSMakeRect(midX, bottomY, bounds.size.width - topLeftSize.width - bottomRightSize.width, bottomRightSize.height) 
                      fromRect:NSRectFromSize([bottomEdgeFill size]) 
                     operation:op 
                      fraction:alphaFraction 
                respectFlipped:YES 
                         hints:nil];
    
    [bottomRightCorner drawInRect:NSMakeRect(rightX, bottomY, bottomRightSize.width, bottomRightSize.height) 
                         fromRect:NSRectFromSize([bottomRightCorner size]) 
                        operation:op 
                         fraction:alphaFraction 
                   respectFlipped:YES 
                            hints:nil];
}