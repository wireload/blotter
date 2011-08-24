//
//  WLCalendarTimeRulerLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 19.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarTimeRuler.h"
#import "WLCalendarTextLayer.h"


@interface WLCalendarTimeRulerLayer : CALayer {
    NSMutableArray *_sortedTimeLayers;
    id<WLCalendarTimeRuler> timeRuler;
    BOOL _shouldUpdatePreferredFrameWidthCache;
    CGFloat _cachedPreferredFrameWidth;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

- (void)setHours:(NSArray *)hours;

- (CGFloat)firstHourYPadding;

- (CGPoint)pointForHour:(CGFloat)aHour;

- (CGFloat)preferredFrameWidth;


- (WLCalendarTextLayer *)_setupTimeLayerWithString:(NSString *)aTime;

@end
