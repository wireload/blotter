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
    NSMutableArray *_sortedByUIDEventLayers;
    NSMutableArray *_icalSortedEventLayers;
}

@property (nonatomic, copy) NSArray *events;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;


- (WLCalendarEventLayer *)_setupEventLayer;

- (void)_updateEventLayer:(WLCalendarEventLayer *)aLayer withEvent:(id)anEvent;

- (NSUInteger)_indexOfEventLayerWithUID:(NSString *)anUID isFound:(out BOOL *)outIsFound;

@end
