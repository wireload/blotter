//
//  WLCalendarAllDayEventsLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


@class WLCalendarEventLayer;


@interface WLCalendarAllDayEventsLayer : CALayer {
    NSMutableArray *_sortedEventLayers;
}

@property (nonatomic, copy) NSArray *events;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;


- (WLCalendarEventLayer *)_setupEventLayerWithEvent:(id)anEvent;

- (NSUInteger)_indexOfEventLayerForUID:(NSString *)anUID isFound:(BOOL *)isFound;

@end
