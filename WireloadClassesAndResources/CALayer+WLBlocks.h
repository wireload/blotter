//
//  CALayer+WLBlocks.h
//  WireloadClassesAndResources
//
//  Created by Ilya Kulakov on 29.01.12.
//  Copyright (c) 2012 WireLoad Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <dispatch/dispatch.h>


@interface CALayer (WLBlocks)

- (void)WL_applyBlockToTree:(void (^)(CALayer *aLayer))aBlock;

@end
