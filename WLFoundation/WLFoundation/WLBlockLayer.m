//
//  WLBlockLayer.m
//  Blotter
//
//  Created by Илья Кулаков on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLBlockLayer.h"

@implementation WLBlockLayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


#pragma mark Properties
@dynamic drawer;


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"drawer"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    if (self.drawer != nil)
    {
        CGContextSaveGState(aContext);
        self.drawer(aContext, self, CGContextGetClipBoundingBox(aContext));
        CGContextRestoreGState(aContext);
    }
}

@end
