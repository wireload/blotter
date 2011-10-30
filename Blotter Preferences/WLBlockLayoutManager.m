//
//  WLBlockLayoutManager.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 30/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLBlockLayoutManager.h"

@implementation WLBlockLayoutManager

- (id)initWithLayoutManager:(WLLayoutManager)aLayoutManager
{
    if (self = [super init]) {
        layoutManager = aLayoutManager;
    }
    
    return self;
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    if (layoutManager != nil)
        layoutManager(layer);
}

@end
