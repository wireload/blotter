//
//  WLBlockLayoutManager.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 30/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//


typedef void (^WLLayoutManager)(CALayer *aLayer);


@interface WLBlockLayoutManager : NSObject {
    WLLayoutManager layoutManager;
}

- (id)initWithLayoutManager:(WLLayoutManager)aLayoutManager;

- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
