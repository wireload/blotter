//
//  WLNinePartBlockLayer.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 28/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//


typedef void (^WLImageDrawer)(CGContextRef aContext);

@interface WLNinePartBlockLayer : CALayer {
    WLImageDrawer drawer;
    
    CGSize upperLeftSize;
    CGSize lowerRightSize;
}

- (id)initWithDrawer:(WLImageDrawer)aDrawer upperLeftSize:(CGSize)upperLeftSize lowerRightSize:(CGSize)lowerRightSize;
- (void)_updateSublayerImages;

@end
