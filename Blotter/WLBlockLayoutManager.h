//
//  WLBlockLayoutManager.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 30/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef void (^WLLayoutManager)(CALayer *aLayer);


@interface WLBlockLayoutManager : NSObject <CALayoutManager>

- (instancetype)initWithLayoutManager:(WLLayoutManager)aLayoutManager NS_DESIGNATED_INITIALIZER;

- (void)layoutSublayersOfLayer:(CALayer *)layer;

@end
