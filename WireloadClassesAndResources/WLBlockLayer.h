//
//  WLBlockLayer.h
//  Blotter
//
//  Created by Илья Кулаков on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@class WLBlockLayer;


typedef void (^WLDrawer)(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect);


@interface WLBlockLayer : CALayer

@property (copy) WLDrawer drawer;

@end
