//
//  CALayer+WLBlocks.m
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 29.01.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import "CALayer+WLBlocks.h"


@implementation CALayer (WLBlocks)

- (void)WL_applyBlockToTree:(void (^)(CALayer *aLayer))aBlock
{
    aBlock(self);
    for (CALayer *l in self.sublayers)
        [l WL_applyBlockToTree:aBlock];
}

@end
