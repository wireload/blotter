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
#import "WLCalendarTimeRulerMarkerLayer.h"


@interface WLCalendarTimeRulerLayer : CALayer {
    NSMutableArray *_sortedMarkerLayers;
    BOOL _needsUpdatePreferredFrameWidthCache;
    BOOL _needsUpdatePreferredMaximumHeightOfMarker;
    CGFloat _cachedPreferredFrameWidth;
    CGFloat _cachedMaximumHeightOfMarker;
}

@property (assign) id<WLCalendarTimeRuler> timeRuler;

@property (getter = isOnlyCompletelyVisibleMarkersShown) BOOL onlyCompletelyVisibleMarkersShown;

@property (nonatomic, copy) NSArray *markers;

- (CGFloat)preferredFrameWidth;

/*!
 @abstract      Returns the maximum height of hour marker.
 @discussion    You may use this value to make sure that hour marker is visible.
 @result        If there are no hours, returns 0.0.
 */
- (CGFloat)maximumHeightOfMarker;

@end


@interface WLCalendarTimeRulerLayer (Layers)

- (WLCalendarTimeRulerMarkerLayer *)setupMarkerLayer;

@end
