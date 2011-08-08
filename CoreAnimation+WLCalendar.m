//
//  CoreAnimation+WLCalendar.m
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "CoreAnimation+WLCalendar.h"


@implementation CATransaction (WLCalendar)

+ (void)WL_performWithDisabledActions:(void (^)(void))aBlock
{
    BOOL old = [self disableActions];
    [self setDisableActions:YES];
    aBlock();
    [self setDisableActions:old];
}

@end
