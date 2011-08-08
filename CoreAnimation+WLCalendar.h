//
//  CoreAnimation+WLCalendar.h
//  Blotter
//
//  Created by Ilya Kulakov on 04.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


@interface CATransaction (WLCalendar)

+ (void)WL_performWithDisabledActions:(void (^)(void))aBlock;

@end
