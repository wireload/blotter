//
//  WLGraphics.h
//  Blotter
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>


/*!
 @abstract      Draws recessed box shadow.
 @discussion    Draws 1px horizontal white line at the bottom. You may want to inset your content to not overlap this line.
 */
void WLRecessedBoxShadow(NSRect frame);

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
                               BOOL flipped);
