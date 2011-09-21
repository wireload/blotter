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
#import "WLCalendarTimeRulerLabelLayer.h"


@interface WLCalendarTimeRulerLayer : CALayer {
    NSMutableArray *_sortedTimeLayers;
    id<WLCalendarTimeRuler> timeRuler;
    BOOL _shouldUpdatePreferredFrameWidthCache;
    CGFloat _cachedPreferredFrameWidth;
    BOOL shouldHideHalfVisibleHourLabels;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property BOOL shouldHideHalfVisibleHourLabels;

- (void)setHours:(NSArray *)hours;

- (CGPoint)pointForHour:(CGFloat)aHour;

- (CGFloat)preferredFrameWidth;

/*!
 @abstract      Returns half of the maximum height of hour label.
 @discussion    You may use this value to make sure that hour label is visible.
 */
- (CGFloat)hourLabelYPadding;

- (WLCalendarTimeRulerLabelLayer *)_setupTimeLayerWithString:(NSString *)aTime;

@end
