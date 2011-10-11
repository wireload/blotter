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
    BOOL _shouldUpdatePreferredFrameWidthCache;
    CGFloat _cachedPreferredFrameWidth;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property BOOL shouldHideHalfVisibleHourLabels;

@property CGFloat heightOfHour;

@property (nonatomic, copy) NSArray *hours;

- (CGPoint)pointForHour:(CGFloat)aHour;

- (CGFloat)preferredFrameWidth;

/*!
 @abstract      Returns the maximum height of hour label. If there are no hours, returns 0.
 @discussion    You may use this value to make sure that hour label is visible.
 */
- (CGFloat)maximumHeightOfHourLabel;

- (WLCalendarTimeRulerLabelLayer *)_setupTimeLayerWithString:(NSString *)aTime;

@end
